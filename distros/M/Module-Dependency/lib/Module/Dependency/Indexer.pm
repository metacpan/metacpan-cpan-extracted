package Module::Dependency::Indexer;

use strict;

use Cwd;
use File::Find;
use File::Spec;
use File::Basename;
use Module::Dependency::Info;

use vars qw/$VERSION $UNIFIED @NOINDEX $check_shebang/;

$VERSION = (q$Revision: 6643 $ =~ /(\d+)/g)[0];

@NOINDEX = qw(.AppleDouble);
my %ignore_names = map { $_ => 1 } qw(
    CVS
    .svn
    .cpan
);
$check_shebang = 1;

our $index_dir;

sub setShebangCheck {
    $check_shebang = shift;
}

sub setIndex {
    my $file = _makeAbsolute(shift);
    return Module::Dependency::Info::setIndex($file);
}

sub buildIndex {
    my @dirs = map { _makeAbsolute($_) } @_;

    TRACE("Running search to build indexes on @dirs");
    $UNIFIED = {};
    my $find_options = {
        wanted => \&_wanted,
        follow => 1,            # follow symbolic links
        follow_skip => 2,       # visit everything only once
        no_chdir => 1,
    };
    my $cwd = getcwd();
    for $index_dir (@dirs) {
        chdir $index_dir or die "Can't chdir $index_dir: $!";
        TRACE("Indexing directory $index_dir");
        File::Find::find( $find_options, $index_dir);
    }
    chdir $cwd or die "Can't return to $cwd dir: $!";
    _reverseDepend();
}

sub makeIndex {
    buildIndex(@_);
    Module::Dependency::Info::storeIndex($UNIFIED);
    return 1;
}

######### PRIVATE

sub _makeAbsolute {
    my $dir = $_[0];
    if ( File::Spec->file_name_is_absolute($dir) ) {
        TRACE("$dir is an absolute path");
        return $dir;
    }
    else {
        my $abs = File::Spec->rel2abs($dir);
        TRACE("$dir is relative - changed to $abs");
        return $abs;
    }
}

# work out and install reverse dependencies
sub _reverseDepend {
    foreach my $Obj ( values( %{ $UNIFIED->{'allobjects'} } ) ) {
        my $item = $Obj->{'package'};
        TRACE("Resolving dependencies for $item");

        # iterate over dependencies...
        foreach my $dep ( @{ $Obj->{'depends_on'} } ) {
            # XXX disabled check for existing item
            # that way packages that are used but not indexed get an obect
            # created for them that captures what depends on them, which is
            # often very useful information
            if ( 1 or exists $UNIFIED->{'allobjects'}->{$dep} ) {

                # put reverse dependencies into packages
                TRACE("Installing reverse dependency in $dep");
                my $obj = $UNIFIED->{'allobjects'}->{$dep} ||= { key => $dep };
                push @{ $obj->{'depended_upon_by'} }, $item;
            }
        }
    }
}

sub _wanted {
    my $fname = $File::Find::name;
    # strip off the current start directory (see buildIndex) to give a relative path
    $fname =~ s/^\Q$index_dir\E\/?//;

    my ($name, $path, $suffix) = fileparse($fname, qr{\..*});
    local $_ = "$name$suffix";

    if ( $ignore_names{$_} ) {
        TRACE("Ignoring $_ ($fname)");
        $File::Find::prune = 1;
        return;
    }
    # XXX generalize into a compiled regex from patterns defined at start/externally
    if (m/(\~|\.bak)$/) {
        TRACE("Ignoring $_ ($fname)");
        return;
    }

    # ignore anything that's not a plain file
    return unless -f $fname;

    my $is = '';
    if (m/\.pm$/) {
        $is = 'module';
    }
    elsif (m/\.plx?$/) {
        $is = 'script';
    }
    elsif ( $check_shebang && -s $fname ) {
        if ( open( F, "<$fname" ) ) {
            my $first_line = <F> || '';
            close F;
            $is = 'script' if $first_line =~ /^#!.*perl/;
            # XXX temp hack to pick up most test script - needs something better
            $is = 'script' if m/\.t$/ && $first_line =~ /^\s*(use\s+|#|package|$)/;
        }
        else {
            warn "Can't open $fname: $!\n";
        }
    }

    if ($is eq 'script') {
        TRACE("script $fname");
        my $obj = _parseScript($fname, $index_dir) || return;
        my $key = $obj->{'filename'};
        $obj->{key} = $key;

        if (my $prev = $UNIFIED->{'allobjects'}->{ $key }) {
            warn_duplicate($prev, $obj, "Filename $key");
        }
        else {
            push @{ $UNIFIED->{'scripts'} }, $key;
        }
        $UNIFIED->{'allobjects'}->{ $key } = $obj;
    }
    elsif ($is eq 'module') {
        TRACE("module $fname");
        my $obj = _parseModule($fname, $index_dir) || return;
        my $key = $obj->{'package'};
        $obj->{key} = $key;
        if (my $prev = $UNIFIED->{'allobjects'}->{ $key }) {
            warn_duplicate($prev, $obj, "Package $key");
        }
        $UNIFIED->{'allobjects'}->{ $key } = $obj;
    }
    else {
        TRACE("ignored $fname");
    }
}

sub warn_duplicate {
    my ($prev_obj, $curr_obj, $what) = @_;
    my $prev_file = $prev_obj->{filename};
    my $curr_file = $curr_obj->{filename};
    if ($prev_file eq $curr_file) {
        # were we're indexing multiple top-level dirs (not recommended) there might
        # be duplicate filenames found - disambiguate this case:
        $prev_file = "$prev_obj->{filerootdir}/$prev_file";
        $curr_file = "$curr_obj->{filerootdir}/$curr_file";
    }
    my $cmp = files_indentical($prev_obj->{filerootdir},$curr_file) ? "files differ" : "files indentical";
    warn "$what seen multiple times ($prev_file superseded by $curr_file, $cmp)\n";
}

sub files_indentical {
    my ($f1, $f2) = @_;
    return 1 if $f1 eq $f2;
    warn "File $f1: $!" unless defined( my $s1 = -s $f1 ); 
    warn "File $f2: $!" unless defined( my $s2 = -s $f2 ); 
    return 0 if $s1 != $s2;
    return system('cmp', '-s', $f1, $f2) == 0;
}


# Get data from a module file, returns a dependency unit object
sub _parseFile {
    my ($file, $rootdir) = @_;

    # ensure key contains a slash so we can use the rule that
    # "if it has a slash in the name then it's not a package"
    $file = "./$file" unless $file =~ m:/:;

    my $self = {
        'filename'         => $file,
        'filerootdir'      => $rootdir,
        'depends_on'       => [],
        'depended_upon_by' => [],
    };

    my %seen;

    # go through the file and try to find out some things
    local *FILE;
    open( FILE, $file ) or do { warn("Can't open file $file for read: $!"); return undef; };

    my $in_pod;
    while (<FILE>) {
        s/\r?\n$//;
        if ($in_pod) {
            $in_pod = 0 if /^=cut/;
            next;
        }

        # get the package name
        if (m/^\s*package\s+([\w\:]+)\s*;/) {
            # XXX currently only record the first package seen
            if (exists $self->{'package'}) {
                warn "Can only index one package per file currently, ignoring $1 at line $. in $file\n";
                next;
            }
            $self->{'package'} = $1;
        }

        # get the dependencies
        if (m/^\s*use\s+([\w\:]+)/) {
            push( @{ $self->{'depends_on'} }, $1 ) unless ( $seen{$1}++ );
        }

        # get the dependencies
        if (m/^\s*require\s+([^\s;]+)/) { # "require Bar;" or "require 'Foo/Bar.pm' if $wibble;'
            my $required = $1;
            if ($required =~ m/^([\w\:]+)$/) {
                push @{ $self->{'depends_on'} }, $required unless $seen{$required}++;
            }
            elsif ($required =~ m/^["'](.*?\.pm)["']$/) { # simple Foo/Bar.pm case
                ($required = $1) =~ s/\.pm$//;
                $required =~ s!/!::!g;
                push @{ $self->{'depends_on'} }, $required unless $seen{$required}++;
            }
            else {
                warn "Can't interpret $_ at line $. in $file\n"
                        unless m!sys/syscall.ph!
                            or m!dumpvar.pl!
                            or $required =~ /^5\./;
            }
        }

        # the 'base' pragma - SREZIC
        if (m/^\s*use\s+base\s+(.*)/) {
            require Safe;
            my $safe = new Safe;
            ( my $list = $1 ) =~ s/\s+\#.*//;
            $list =~ s/[\r\n]//;
            while ( $list !~ /;\s*$/ && ( $_ = <FILE> ) ) {
                s/\s+#.*//;
                s/[\r\n]//;
                $list .= $_;
            }
            $list =~ s/;\s*$//;
            my (@mods) = $safe->reval($list);
            warn "Unable to eval $_ at line $. in $file: $@\n" if $@;
            foreach my $mod (@mods) {
                push( @{ $self->{'depends_on'} }, $mod ) unless ( $seen{$mod}++ );
            }
        }

        $in_pod = 1 if m/^=\w+/ && !m/^=cut/;
        last if m/^\s*__(END|DATA)__/;
    }
    close FILE;

    return $self;
}

# Get data from a module file, returns a dependency unit object
sub _parseModule {
    my ($file, $rootdir) = @_;
    my $self = _parseFile($file, $rootdir)
        or return;
    if ( !$self->{'package'} ) {
        warn "No package found in $file\n";
        return undef;
    }
    return $self;
}

# Get data from a program file, returns a dependency unit object
sub _parseScript {
    my ($file, $rootdir) = @_;
    my $self = _parseFile($file, $rootdir)
        or return;

    # XXX force package for script file to be the filename
    warn "Ignored package ($self->{'package'}) within script $file\n"
        if $self->{'package'} && $self->{'package'} ne 'main';
    $self->{'package'} = $self->{filename};

    return $self;
}

sub TRACE { }
sub LOG   { }

1;

=head1 NAME

Module::Dependency::Indexer - creates the databases used by the dependency mapping module

=head1 SYNOPSIS

	use Module::Dependency::Indexer;
	Module::Dependency::Indexer::setIndex( '/var/tmp/dependency/unified.dat' );
	Module::Dependency::Indexer::makeIndex( $directory, [ $another, $andanother... ] );
	Module::Dependency::Indexer::setShebangCheck( 0 );

=head1 DESCRIPTION

This module looks at all .pm, .pl and .plx files within and below a given directory/directories 
(found with File::Find), reads through them and extracts some information about them.
If the shebang check is turned on then it also looks at the first line of all
other files, to see if they're perl programs too. We extract this information:

=over 4

=item *

The name of the package (e.g. 'Foo::Bar') or the name of the script (e.g. 'chat.pl')

=item *

The full filesystem location of the file.

=item *

The dependencies of the file - i.e. the packages that it 'use's or 'require's

=item *

The reverse dependencies - i.e. what other scripts and modules B<THAT IT HAS INDEXED> use or require
the file. It can't, of course, know about 'use' statements in files it hasn't examined.

=back

When it has extracted all this information it uses Storable to write the data to disk in the indexfile location.

This search is quite an expensive operation, taking around 10 seconds for the site_perl directory here.
However once the information has been gathered it's extremely fast to use.

=head1 FUNCTIONS

=over 4

=item setIndex( $filename )

This function tells the module where to write out the datafile. You can set this, make an index 
of some directory of perl stuff, set it to something else, index a different folder, etc., in order 
to build up many indices. This only affects this module - you need to tell ...::Info where to look 
for datafiles independently of this module.

Default is /var/tmp/dependence/unified.dat

=item makeIndex( $directory, [ $another, $andanother... ] )

Builds, and stores to the current data file, a SINGLE database for all the files found under 
all of the supplied directories. To create multiple indexes, run this method many times with a setIndex 
inbetween each so that you don't clobber the previous run's datafile.

=item setShebangCheck( BOOLEAN )

Turns on or off the checking of #! lines for all files that are not .pl, .plx or .pm filenames.
By default we do check the #! lines.

=back

=head1 NOTE ABOUT WHAT IS INDEXED

A database entry is made for B<each file scanned>. This makes the generally good assumption that a .pl file is
a script that is not use/required by anything else, and a .pm file is a package file which may be use/required
by many other files. Database entries ARE NOT made just because a file is use/required - hence the database
will not contain an entry for 'strict' or 'File::Find' (for example) unless you explicitly index your perl's lib/ folder.

E.g., if 'Local::Foo.pm' uses strict and File::Find and we index it, its entry in the database will show that it 
depends on strict and File::Find, as you'd expect. It's just that we won't create an entry for 'strict' on that basis alone.

In practice this behaviour is what you want - you want to see how the mass of perl in your cgi-bin and site_perl folders
fits together (for example), or maybe just a single project in CVS.
You may of course include your perl lib directory in the database should you want to see the dependencies involving
the standard modules, but generally that's not relevant.

=head1 USE OF THE DATA

Now you've got a datafile which links all the scripts and modules in a set of directories. Use ...::Info to get at the data.
Note that the data is stored using Storable's nstore method which _should_ make these indexes portable across platforms.
Not tested though.

=head1 ADVICE, GETTING AT DATA

As Storable is so fast, you may want to make one big index of all folders where perl things are. Then you can load this 
datafile back up, extract the entry for, say, Local::Foo and examine its dependencies (and reverse dependencies). 
Based on what you find, you can get the entries for Local::Foo::Bar and Local::Foo::Baz (things used by Local::Foo) or
perhaps Local::Stuff (which uses Local::Foo). Then you can examine those records, etc. This is how ...::Grapher builds
the tree of dependencies, basically.

You use Module::Dependency::Info to get at these records using a nice simple API. If you're feeling keen you can just
grab the entire object - but that's in the ...::Info module.

Here we have a single index for all our local perl code, and that lives in /var/tmp/dependence/unified.dat - the default
location. Other applications just use that file.

=head1 DEBUGGING

There is a TRACE stub function, and the module uses TRACE() to log activity. Override our TRACE with your own routine, e.g.
one that prints to STDERR, to see these messages.

=head1 SEE ALSO

Module::Dependency and the README files.

=head1 VERSION

$Id: Indexer.pm 6643 2006-07-12 20:23:31Z timbo $

=cut


