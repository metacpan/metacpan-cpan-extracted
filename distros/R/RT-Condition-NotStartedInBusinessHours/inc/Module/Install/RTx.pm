package Module::Install::RTx;

use 5.008;
use strict;
use warnings;
no warnings 'once';

use Module::Install::Base;
use base 'Module::Install::Base';
our $VERSION = '0.29';

use FindBin;
use File::Glob     ();
use File::Basename ();

my @DIRS = qw(etc lib html bin sbin po var);
my @INDEX_DIRS = qw(lib bin sbin);

sub RTx {
    my ( $self, $name ) = @_;

    my $original_name = $name;
    my $RTx = 'RTx';
    $RTx = $1 if $name =~ s/^(\w+)-//;
    my $fname = $name;
    $fname =~ s!-!/!g;

    $self->name("$RTx-$name")
        unless $self->name;
    $self->all_from( -e "$name.pm" ? "$name.pm" : "lib/$RTx/$fname.pm" )
        unless $self->version;
    $self->abstract("RT $name Extension")
        unless $self->abstract;

    my @prefixes = (qw(/opt /usr/local /home /usr /sw ));
    my $prefix   = $ENV{PREFIX};
    @ARGV = grep { /PREFIX=(.*)/ ? ( ( $prefix = $1 ), 0 ) : 1 } @ARGV;

    if ($prefix) {
        $RT::LocalPath = $prefix;
        $INC{'RT.pm'} = "$RT::LocalPath/lib/RT.pm";
    } else {
        local @INC = (
            $ENV{RTHOME} ? ( $ENV{RTHOME}, "$ENV{RTHOME}/lib" ) : (),
            @INC,
            map { ( "$_/rt4/lib", "$_/lib/rt4", "$_/rt3/lib", "$_/lib/rt3", "$_/lib" )
                } grep $_, @prefixes
        );
        until ( eval { require RT; $RT::LocalPath } ) {
            warn
                "Cannot find the location of RT.pm that defines \$RT::LocalPath in: @INC\n";
            $_ = $self->prompt("Path to directory containing your RT.pm:") or exit;
            $_ =~ s/\/RT\.pm$//;
            push @INC, $_, "$_/rt3/lib", "$_/lib/rt3", "$_/lib";
        }
    }

    my $lib_path = File::Basename::dirname( $INC{'RT.pm'} );
    my $local_lib_path = "$RT::LocalPath/lib";
    print "Using RT configuration from $INC{'RT.pm'}:\n";
    unshift @INC, "$RT::LocalPath/lib" if $RT::LocalPath;
    unshift @INC, $lib_path;

    $RT::LocalVarPath  ||= $RT::VarPath;
    $RT::LocalPoPath   ||= $RT::LocalLexiconPath;
    $RT::LocalHtmlPath ||= $RT::MasonComponentRoot;
    $RT::LocalLibPath  ||= "$RT::LocalPath/lib";

    my $with_subdirs = $ENV{WITH_SUBDIRS};
    @ARGV = grep { /WITH_SUBDIRS=(.*)/ ? ( ( $with_subdirs = $1 ), 0 ) : 1 }
        @ARGV;

    my %subdirs;
    %subdirs = map { $_ => 1 } split( /\s*,\s*/, $with_subdirs )
        if defined $with_subdirs;
    unless ( keys %subdirs ) {
        $subdirs{$_} = 1 foreach grep -d "$FindBin::Bin/$_", @DIRS;
    }

    # If we're running on RT 3.8 with plugin support, we really wany
    # to install libs, mason templates and po files into plugin specific
    # directories
    my %path;
    if ( $RT::LocalPluginPath ) {
        die "Because of bugs in RT 3.8.0 this extension can not be installed.\n"
            ."Upgrade to RT 3.8.1 or newer.\n" if $RT::VERSION =~ /^3\.8\.0/;
        $path{$_} = $RT::LocalPluginPath . "/$original_name/$_"
            foreach @DIRS;
    } else {
        foreach ( @DIRS ) {
            no strict 'refs';
            my $varname = "RT::Local" . ucfirst($_) . "Path";
            $path{$_} = ${$varname} || "$RT::LocalPath/$_";
        }

        $path{$_} .= "/$name" for grep $path{$_}, qw(etc po var);
    }

    my %index = map { $_ => 1 } @INDEX_DIRS;
    $self->no_index( directory => $_ ) foreach grep !$index{$_}, @DIRS;

    my $args = join ', ', map "q($_)", map { ($_, $path{$_}) }
        grep $subdirs{$_}, keys %path;

    print "./$_\t=> $path{$_}\n" for sort keys %subdirs;

    if ( my @dirs = map { ( -D => $_ ) } grep $subdirs{$_}, qw(bin html sbin) ) {
        my @po = map { ( -o => $_ ) }
            grep -f,
            File::Glob::bsd_glob("po/*.po");
        $self->postamble(<< ".") if @po;
lexicons ::
\t\$(NOECHO) \$(PERL) -MLocale::Maketext::Extract::Run=xgettext -e \"xgettext(qw(@dirs @po))\"
.
    }

    my $postamble = << ".";
install ::
\t\$(NOECHO) \$(PERL) -MExtUtils::Install -e \"install({$args})\"
.

    if ( $subdirs{var} and -d $RT::MasonDataDir ) {
        my ( $uid, $gid ) = ( stat($RT::MasonDataDir) )[ 4, 5 ];
        $postamble .= << ".";
\t\$(NOECHO) chown -R $uid:$gid $path{var}
.
    }

    my %has_etc;
    if ( File::Glob::bsd_glob("$FindBin::Bin/etc/schema.*") ) {

        # got schema, load factory module
        $has_etc{schema}++;
        $self->load('RTxFactory');
        $self->postamble(<< ".");
factory ::
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxFactory(qw($RTx $name))"

dropdb ::
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxFactory(qw($RTx $name drop))"

.
    }
    if ( File::Glob::bsd_glob("$FindBin::Bin/etc/acl.*") ) {
        $has_etc{acl}++;
    }
    if ( -e 'etc/initialdata' ) { $has_etc{initialdata}++; }

    $self->postamble("$postamble\n");
    unless ( $subdirs{'lib'} ) {
        $self->makemaker_args( PM => { "" => "" }, );
    } else {
        $self->makemaker_args( INSTALLSITELIB => $path{'lib'} );
        $self->makemaker_args( INSTALLARCHLIB => $path{'lib'} );
    }

    $self->makemaker_args( INSTALLSITEMAN1DIR => "$RT::LocalPath/man/man1" );
    $self->makemaker_args( INSTALLSITEMAN3DIR => "$RT::LocalPath/man/man3" );
    $self->makemaker_args( INSTALLSITEARCH => "$RT::LocalPath/man" );

    if (%has_etc) {
        $self->load('RTxInitDB');
        print "For first-time installation, type 'make initdb'.\n";
        my $initdb = '';
        $initdb .= <<"." if $has_etc{schema};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(schema))"
.
        $initdb .= <<"." if $has_etc{acl};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(acl))"
.
        $initdb .= <<"." if $has_etc{initialdata};
\t\$(NOECHO) \$(PERL) -Ilib -I"$local_lib_path" -I"$lib_path" -Minc::Module::Install -e"RTxInitDB(qw(insert))"
.
        $self->postamble("initdb ::\n$initdb\n");
        $self->postamble("initialize-database ::\n$initdb\n");
    }
}

sub RTxInit {
    unshift @INC, substr( delete( $INC{'RT.pm'} ), 0, -5 ) if $INC{'RT.pm'};
    require RT;
    RT::LoadConfig();
    RT::ConnectToDatabase();

    die "Cannot load RT" unless $RT::Handle and $RT::DatabaseType;
}

# stolen from RT::Handle so we work on 3.6 (cmp_versions came in with 3.8)
{ my %word = (
    a     => -4,
    alpha => -4,
    b     => -3,
    beta  => -3,
    pre   => -2,
    rc    => -1,
    head  => 9999,
);
sub cmp_version($$) {
    my ($a, $b) = (@_);
    my @a = grep defined, map { /^[0-9]+$/? $_ : /^[a-zA-Z]+$/? $word{$_}|| -10 : undef }
        split /([^0-9]+)/, $a;
    my @b = grep defined, map { /^[0-9]+$/? $_ : /^[a-zA-Z]+$/? $word{$_}|| -10 : undef }
        split /([^0-9]+)/, $b;
    @a > @b
        ? push @b, (0) x (@a-@b)
        : push @a, (0) x (@b-@a);
    for ( my $i = 0; $i < @a; $i++ ) {
        return $a[$i] <=> $b[$i] if $a[$i] <=> $b[$i];
    }
    return 0;
}}
sub requires_rt {
    my ($self,$version) = @_;

    # if we're exactly the same version as what we want, silently return
    return if ($version eq $RT::VERSION);

    my @sorted = sort cmp_version $version,$RT::VERSION;

    if ($sorted[-1] eq $version) {
        # should we die?
        warn "\nWarning: prerequisite RT $version not found. Your installed version of RT ($RT::VERSION) is too old.\n\n";
    }
}

1;

__END__

=head1 NAME

Module::Install::RTx - RT extension installer

=head1 SYNOPSIS

In the F<Makefile.PL> of the C<RT-Extension-Foo> module:

    use inc::Module::Install;
    RTx 'RT-Extension-Foo';
    WriteAll();

optionally add a

    requires_rt('3.8.9');

to warn if your RT version is too old during install

=head1 DESCRIPTION

This B<Module::Install> extension implements one function, C<RTx>,
that takes the extension name as the only argument.

It arranges for certain subdirectories to install into the installed
RT location, but does not affect the usual C<lib> and C<t> directories.

The directory mapping table is as below:

    ./bin   => $RT::LocalPath/bin
    ./etc   => $RT::LocalPath/etc/$NAME
    ./html  => $RT::MasonComponentRoot
    ./po    => $RT::LocalLexiconPath/$NAME
    ./sbin  => $RT::LocalPath/sbin
    ./var   => $RT::VarPath/$NAME

Under the default RT3 layout in F</opt> and with the extension name
C<Foo>, it becomes:

    ./bin   => /opt/rt3/local/bin
    ./etc   => /opt/rt3/local/etc/Foo
    ./html  => /opt/rt3/share/html
    ./po    => /opt/rt3/local/po/Foo
    ./sbin  => /opt/rt3/local/sbin
    ./var   => /opt/rt3/var/Foo

By default, all these subdirectories will be installed with C<make install>.
you can override this by setting the C<WITH_SUBDIRS> environment variable to
a comma-delimited subdirectory list, such as C<html,sbin>.

Alternatively, you can also specify the list as a command-line option to
C<Makefile.PL>, like this:

    perl Makefile.PL WITH_SUBDIRS=sbin

=head1 CAVEATS

=over 4

=item * Use full name when call RTx method in Makefile.PL, some magic has been
implemented in this installer to support RTx('Foo') for 'RTx-Foo' extension, but
life proved that it's bad idea. Code still there for backwards compatibility.
It will be deleted eventually.

=item * installer want work with RT 3.8.0, as it has some bugs new plugins
sub-system.

=item * layout of files has been changed between RT 3.6 and RT 3.8, old files
may influence behaviour of your extension. Recommend people use clean dir on
upgrade or guide how to remove old versions of your extension.

=back

=head1 ENVIRONMENT

=over 4

=item RTHOME

Path to the RT installation that contains a valid F<lib/RT.pm>.

=back

=head1 SEE ALSO

L<Module::Install>

L<http://www.bestpractical.com/rt/>

=head1 AUTHORS

Audrey Tang <cpan@audreyt.org>

=head1 COPYRIGHT

Copyright 2003, 2004, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
