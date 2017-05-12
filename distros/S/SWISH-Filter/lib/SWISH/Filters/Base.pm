package SWISH::Filters::Base;
use strict;
use Carp;
use vars qw( $VERSION );

$VERSION = '0.191';

=pod

=head1 NAME

SWISH::Filters::Base - base class for SWISH::Filters

=head1 DESCRIPTION

Each filter is a subclass of SWISH::Filters::Base.  A number of methods
are available by default (and some can be overridden).  Others are useful
when writing your new() constructor.


=head1 METHODS

=head2 filter

You B<must> override this method in your filter subclass.

=cut

sub filter {
    my $class = ref( shift(@_) );
    croak "$class must implement a filter() method";
}

=head2 parent_filter

This method is no longer supported.

=cut

sub parent_filter {
    croak "parent_filter is no longer supported";
}

=head2 type

This method fetches the type of the filter.  The value returned sets the
primary sort key for sorting the filters.  You can override this in your
filter, or just set it as an attribute in your object.  The default is 2.

The idea of the "type" is to create groups of filters, if needed.
For example, you might have a set of filters that are used for uncompressing
some documents before passing on to another group for filtering.

=cut

sub type { $_[0]->{type} || 2 }

=head2 priority

This method fetches the priority of the filter.  The value returned sets the
secondary sort key for sorting the filters.  You can override this in your
filter, or just set it as an attribute in your object.  The default method
returns 50.

The priority is useful if you have multiple filters for the same content type that
use different methods for filtering (say one uses wvWare and another uses catdoc for
filtering MS Word files).  You might give the wvWare filter a lower priority number
so it runs before the catdoc filter if both wvWare AND catdoc happen to be installed
at the same time.

A lower priority value is given preference over a higher priority value.

=cut

sub priority { $_[0]->{priority} || 50 }

=head2 mimetypes

Returns the list of mimetypes (as regular expressions) set for the filter.

=cut

sub mimetypes {
    my $self = shift;
    croak "Filter [$self] failed to set 'mimetypes' in new() constructor\n"
        if !$self->{mimetypes};

    croak "Filter [$self] 'mimetypes' entry is not an array reference\n"
        unless ref $self->{mimetypes} eq 'ARRAY';

    return @{ $self->{mimetypes} };
}

=head2 can_filter_mimetype( I<content_type> )

Returns true if passed in content type matches one of the filter's mimetypes
Returns the pattern that matched.

=cut

sub can_filter_mimetype {
    my ( $self, $content_type ) = @_;

    croak "Must supply content_type to can_filter_mimetype()"
        unless $content_type;
    for my $pattern ( $self->mimetypes ) {
        return $pattern if $content_type =~ /$pattern/;
    }
    return;
}

=head2 mywarn( I<message> )

Prints I<message> on STDERR if debugging is set with FILTER_DEBUG environment
variable.

=cut

sub mywarn {
    my $self = shift;

    print STDERR "Filter: $self: ", @_, "\n" if $ENV{FILTER_DEBUG};
}

=head2 set_programs( @I<program_list> );

Creates a method for each
program with the "run_" prefix.  Returns undef if B<any> program cannot
be found.

If all the programs listed in @I<program_list> are found
and can be executed as the current user,
set_programs() returns $self, so you can chain methods together.

For example, in your constructor you might do:

    return $self->set_programs( qw/ pdftotext pdfinfo / );

Then in your filter() method:

    my $content = $self->run_pdfinfo( $doc->fetch_filename, [options] );

=cut

sub set_programs {
    my ( $self, @progs ) = @_;

    for my $prog (@progs) {
        my $path = $self->find_binary($prog);
        unless ($path) {
            $self->mywarn(
                "Can not use Filter: failed to find $prog.  Maybe need to install?"
            );
            return;
        }

        if ( !$self->can("run_${prog}") ) {
            no strict 'refs';
            *{"run_$prog"} = sub {
                return shift->run_program( $path, @_ );    # closure
            };
        }
    }

    return $self;
}

=head2 find_binary( I<prog> );

Use in a filter's new() method to test for a necesary program located in C<$ENV{PATH}>.
Returns the path to the program if I<prog> exists and passes the built-in C<-x> test.
Returns undefined otherwise.

=cut

use Config;
my @path_segments;

sub find_binary {
    my ( $self, $prog ) = @_;

    unless (@path_segments) {
        my $path_sep = $Config{path_sep} || ':';

        @path_segments = split /\Q$path_sep/, $ENV{PATH};

        if ( my $libexecdir = get_libexec() ) {
            push @path_segments, $libexecdir;
        }
    }

    $self->mywarn( "Find path of [$prog] in " . join ':', @path_segments );

    for (@path_segments) {
        my $path = "$_/$prog";

# For buggy Windows98 that accepts forward slashes if the filename isn't too long
        $path =~ s[/][\\]g if $^O =~ /Win32/;

        if ( -x $path ) {

            $self->mywarn(" * Found program at: [$path]\n");
            return $path;
        }
        $self->mywarn("  Not found at path [$path]");

        # ok, try Windows extenstions
        if ( $^O =~ /Win32/ ) {
            for my $extension (qw/ exe bat /) {
                if ( -x "$path.$extension" ) {
                    $self->mywarn(
                        " * Found program at: [$path.$extension]\n");
                    return "$path.$extension";
                }
                $self->mywarn("  Not found at path [$path.$extension]");
            }
        }

    }
    return;
}

# Try and return libexecdir in case programs are installed there (the case with Windows)
# Assumes that we are running from libexecdir or bindir
# The other option under Windows would be to fetch libexecdir from the Windows registry,
# but that could break if a new (another) swish install was done since the registry
# would then point to the new install location.

sub get_libexec {

    # karman changed to return just 'swish-e' and rely on PATH to find it
    return 'swish-e';
}

=head2 use_modules( @I<module_list> );

Attempts to load each of the modules listed and call its import() method.

Use to test and load required modules within a filter without aborting.

    return unless $self->use_modules( qw/ Spreadsheet::ParseExcel  HTML::Entities / );

If the module name is an array reference, the first item is considered the module
name and the second the minimum version required.

    return unless $self->use_modules( [ 'Foo::Bar' => '0.123' ] );

Returns undef if any module is unavailable.
A warning message is displayed if the FILTER_DEBUG environment variable is true.

Returns C<$self> on success.


=cut

sub use_modules {
    my ( $self, @modules ) = @_;

    for my $module (@modules) {
        my $req_vers = 0;
        my $mod;
        if ( ref $module ) {
            ( $mod, $req_vers ) = @$module;
        }
        else {
            $mod = $module;
        }

        $self->mywarn("trying to load [$mod $req_vers]");

        if ($req_vers) {
            eval { eval "use $mod $req_vers"; die "$@\n" if $@; };
        }
        else {
            eval { eval "require $mod" or die "$!\n" };
        }

        if ($@) {
            my $err    = $@;
            my $caller = caller();
            $self->mywarn(
                "Can not use Filter $caller -- need to install $mod $req_vers: $err"
            );
            return;
        }

        $self->mywarn(" ** Loaded $mod **");

        # Export back to caller
        $mod->export_to_level(1) if $mod->can('export_to_level');
    }
    return $self;
}

=head2 run_program( I<program>, @I<args> );

Runs I<program> with @I<args>.  Must pass in @args.

Under Windows calls IPC::Open2, which may pass data through the shell.  Double-quotes are
escaped (backslashed) and each parameter is wrapped in double-quotes.

On other platforms a fork() and exec() is used to avoid passing any data through the shell.

Returns a reference to a scalar containing the output from your program, or croaks.

This method is intended to read output from a program that converts one format into text.
The output is read back in text mode -- on systems like Windows this means \r\n (CRLF) will
be convertet to \n.

=cut

sub run_program {
    my $self = shift;

    croak "No arguments passed to run_program()\n"
        unless @_;

    croak "Must pass arguments to program '$_[0]'\n"
        unless @_ > 1;

    my $fh
        = $^O =~ /Win32/i || $^O =~ /VMS/i
        ? $self->windows_fork(@_)
        : $self->real_fork(@_);

    local $/ = undef;
    my $output = <$fh>;
    close $fh;

    # When using IPC::Open3 need to reap the processes.
    waitpid delete $self->{pid}, 0 if $self->{pid};

    return $output;
}

#==================================================================
# Run swish-e by forking
#

use Symbol;

sub real_fork {
    my ( $self, @args ) = @_;

    # Run swish
    my $fh = gensym;
    my $pid = open( $fh, '-|' );

    croak "Failed to fork: $!\n" unless defined $pid;

    return $fh if $pid;

    delete $self->{temp_file}; # in child, so don't want to delete on destroy.

    exec @args or exit;        # die "Failed to exec '$args[0]': $!\n";
}

#=====================================================================================
# Need
#
sub windows_fork {
    my ( $self, @args ) = @_;

    require IPC::Open2;
    my ( $rdrfh, $wtrfh );

    my @command = map { s/"/\\"/g; qq["$_"] } @args;

    my $pid = IPC::Open2::open2( $rdrfh, $wtrfh, @command );

    # IPC::Open3 uses binmode for some reason (5.6.1)
    # Assume that the output from the program will be in text
    # Maybe an invalid assumption if running through a binary filter

    binmode $rdrfh, ':crlf'; # perhpaps: unless delete $self->{binary_output};

    $self->{pid} = $pid;

    return $rdrfh;
}

=head2 escapeXML( I<string> )

Escapes the 5 primary XML characters & < > ' and ", plus all ASCII control
characters. Returns the escaped string.

=cut

sub escapeXML {
    my $self = shift;
    my $str  = shift;

    return '' unless defined $str;

    $str =~ s/[\x00-\x1f]/\n/go;    # converts all low chars to LF

    for ($str) {
        s/&/&amp;/go;
        s/"/&quot;/go;
        s/</&lt;/go;
        s/>/&gt;/go;
        s/'/&apos;/go;
    }
    return $str;
}

=head2 format_meta_headers( I<meta_hash_ref> )

Returns XHTML-compliant C<meta> tags as a scalar, suitable for inserting into the C<head>
tagset of HTML or anywhere in an XML doc.

I<meta_hash_ref> should be a hash ref of name/content pairs. Both name and content
will be run through escapeXML for you, so do B<not> escape them yourself or you
run the risk of double-escaped text.

=cut

sub format_meta_headers {
    my $self = shift;
    my $m = shift or croak "need meta hash ref";
    croak "$m is not a hash ref" unless ref $m and ref $m eq 'HASH';

    my $metas = join "\n", map {
              '<meta name="'
            . $self->escapeXML($_)
            . '" content="'
            . $self->escapeXML( $m->{$_} ) . '"/>';

    } sort keys %$m;

    return $metas;
}

1;

__END__

=head1 TESTING

Filters can be tested with the F<swish-filter-test> program in the C<example/>
directory. Run:

   swish-filter-test -man

for documentation.

=head1 SUPPORT

Please contact the Swish-e discussion list.  http://swish-e.org


=head1 AUTHOR

Bill Moseley

Currently maintained by Peter Karman C<perl@peknet.com>.

=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=cut
