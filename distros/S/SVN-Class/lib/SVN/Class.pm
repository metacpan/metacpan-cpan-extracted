package SVN::Class;
use strict;
use warnings;
use base qw( Path::Class Rose::Object );
use Rose::Object::MakeMethods::Generic (
    scalar => [qw( svn stdout stderr error error_code verbose debug )] );
use Carp;
use Data::Dump;
use IPC::Cmd qw( can_run run );
use SVN::Class::File;
use SVN::Class::Dir;
use SVN::Class::Info;
use Text::ParseWords;
use File::Temp;

$ENV{LC_ALL} = 'C';    # we expect our responses in ASCII

#$IPC::Cmd::DEBUG   = 1;
#$IPC::Cmd::VERBOSE = 1;

unless ( IPC::Cmd->can_capture_buffer ) {
    croak "IPC::Cmd is not configured to capture buffers. "
        . "Do you have IPC::Run installed?";
}

# IPC::Run fails tests because we use built-in shell commands
# not found in PATH
$IPC::Cmd::USE_IPC_RUN = 1;

# this trick cribbed from mst's Catalyst::Controller::WrapCGI
# we alias STDIN and STDOUT since Catalyst (and presumaly other code)
# might be messing with STDOUT or STDIN
my $REAL_STDIN  = *STDIN;
my $REAL_STDOUT = *STDOUT;
my $REAL_STDERR = *STDERR;
if ( $ENV{SVN_CLASS_ALIAS_STDOUT} ) {
    open $REAL_STDIN,  "<&=" . CORE::fileno(*STDIN);
    open $REAL_STDOUT, ">>&=" . CORE::fileno(*STDOUT);
    open $REAL_STDERR, ">>&=" . CORE::fileno(*STDERR);
}

sub _debug_stdin_fh {

    #warn "     stdin fileno = " . CORE::fileno(*STDIN);
    #warn "real_stdin fileno = " . CORE::fileno($REAL_STDIN);
}

sub _debug_stdout_fh {

    #warn "     stdout fileno = " . CORE::fileno(*STDOUT);
    #warn "real_stdout fileno = " . CORE::fileno($REAL_STDOUT);
}

our @EXPORT    = qw( svn_file svn_dir );
our @EXPORT_OK = qw( svn_file svn_dir );

our $VERSION = '0.18';

=head1 NAME

SVN::Class - manipulate Subversion workspaces with Perl objects

=head1 SYNOPSIS

 use SVN::Class;
 
 my $file = svn_file( 'path/to/file' );
 my $fh = $file->open('>>');
 print {$fh} "hello world\n";
 $fh->close;
 $file->add;
 if ($file->modified) {
    my $rev = $file->commit('the file changed');
    print "$file was committed with revision $rev\n";
 }
 else {
    croak "$file was not committed: " . $file->errstr;
 }
 
 my $dir = svn_dir( 'path/to/dir' );
 $dir->mkpath unless -d $dir;
 $dir->add;  # recurses by default
 $dir->commit('added directory') if $dir->modified;
 
=head1 DESCRIPTION

SVN::Class extends Path::Class to allow for basic Subversion workspace
management. SVN::Class::File and SVN::Class::Dir are subclasses of
Path::Class::File::Stat and Path::Class::Dir respectively.

SVN::Class does not use the SVN::Core Subversion SWIG bindings. Instead,
the C<svn> binary tool is used for all interactions, using IPC::Cmd. This
design decision was made for maximum portability and to eliminate
non-CPAN dependencies.

=head1 EXPORT

SVN::Class exports two functions by default: svn_file() and svn_dir().
These work just like the dir() and file() functions in Path::Class.
If you do not want to export them, just invoke SVN::Class like:

 use SVN::Class ();

=head2 svn_file( I<file> )

Works just like Path::Class::file().

=head2 svn_dir( I<dir> )

Works just like Path::Class::dir().

=cut

sub svn_file {
    SVN::Class::File->new(@_);
}

sub svn_dir {
    SVN::Class::Dir->new(@_);
}

=head1 METHODS

SVN::Class inherits from Path::Class. Only new or overridden methods
are documented here.

=cut

=head2 svn

Path to the svn binary. Defaults to C<svn> and thus relies on environment's
PATH to find and execute the correct command.

=head2 stdout

Get the stdout from the last svn_run().

=head2 stderr

Get the stderr from the last svn_run().

=head2 error

If the last svn_run() exited with non-zero, error() will return same
as stderr(). If svn_run() was successful, returns the empty string.

=head2 error_code

Returns the last exit value of svn_run().

=head2 verbose

Get/set a true value to enable IPC output in svn_run().

=head2 debug

Get/set a true value to see debugging output printed on stderr.

=cut

=head2 svn_run( I<cmd>, I<opts>, I<file> )

Execute I<cmd> given I<opts> and I<file> as arguments. This is a wrapper
around the IPC::Run run() function.

I<opts> should be an array ref of options to pass to I<cmd>.

I<file> defaults to $self->stringify().

Returns the success code from IPC::Run run(). Sets the stdout,
stderr, err, errstr, and error_code values in the SVN::Class object.

This method is used internally by all the Subversion commands.

B<NOTE:> In order to standardize the output of Subversion commands into
a locale that is easily parse-able by other methods that call svn_run()
internally, all commands are run with C<LC_ALL=C> to make sure
output is ASCII only.

=cut

sub svn_run {
    my $self = shift;
    my $cmd  = shift or croak "svn command required";
    my $opts = shift || [];
    my $file = shift || "$self";

    # since $opts may contain whitespace, must pass command as array ref
    # to IPC::Run
    my $command
        = [ $self->svn, $cmd, shellwords( join( ' ', @$opts ) ), $file ];

    my @out;

    $self->_debug_stdin_fh;
    $self->_debug_stdout_fh;

    {
        local *STDIN  = $REAL_STDIN;    # restore the real ones so the filenos
        local *STDOUT = $REAL_STDOUT;   # are 0 and 1 for the env setup
        local *STDERR = $REAL_STDERR;

        my $old = select($REAL_STDOUT);  # in case somebody just calls 'print'

        # Use local signal handler so global handler
        # does not result in bad values in $? and $!
        # http://www.perlmonks.org/?node_id=197500
        # useful for running under Catalyst (e.g.)
        local $SIG{CHLD} = '';

        $self->_debug_stdin_fh;
        $self->_debug_stdout_fh;

        (@out) = run( command => $command, verbose => $self->verbose );

        select($old);
    }

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) = @out;

    # buffers do not always split on \n so force them to.
    my @stdout = split( m/\n/, join( '', @$stdout_buf ) );
    my @stderr = split( m/\n/, join( '', @$stderr_buf ) );

    # return code is a little murky as $error_code is often -1
    # which sometimes signals success, while $success is undef.
    if ( !defined($success) ) {
        if ( $error_code eq '-1' && !@stderr ) {
            $success = 1;
        }
        else {
            $success = 0;
        }
    }

    $self->stdout( \@stdout );
    $self->stderr( \@stderr );
    $self->error( $success ? "" : \@stderr );
    $self->error_code($error_code);

    if ( $self->debug || $ENV{PERL_DEBUG} ) {
        carp "command: " . Data::Dump::dump($command);
        carp Data::Dump::dump \@out;
        $self->dump;
        carp "success = $success";
    }

    return $success;
}

=head2 log

Returns svn log of the file or 0 on error. The log is returned
as an arrayref (same as accessing stdout()).

=cut

sub log {
    my $self = shift;
    my $ret = $self->svn_run( 'log', @_ );
    return 0 unless $ret > 0;
    return $self->stdout;
}

=head2 add

Schedule the object for addition to the repository.

=cut

sub add {
    shift->svn_run( 'add', @_ );
}

=head2 delete

Schedule the object for removal from the repository.

=cut

sub delete {
    shift->svn_run( 'rm', @_ );
}

=head2 update

Get the latest version of the object from the repository.

=cut

sub update {
    shift->svn_run( 'update', @_ );
}

=head2 up

Alias for update().

=cut

*up = \&update;

=head2 revert

Undo the last Subversion action on the object.

=cut

sub revert {
    shift->svn_run( 'revert', @_ );
}

=head2 commit( I<message> )

Commit the object to the repository with the log I<message>.

Returns the revision number of the commit on success, 0 on failure.

=cut

sub commit {

    # croak if failure but set error() and error_code()
    # first in case wrapped in eval().
    my $self    = shift;
    my $message = shift or croak "commit message required";
    my $opts    = shift || [];

    # create temp file to print message to. see RT #48748
    my $message_fh = File::Temp->new();
    print $message_fh $message;
    my $message_file = $message_fh->filename;
    $message_file =~ s!\\!/!g;  # escape literal \ for Windows users. see RT#54969

    my $ret = $self->svn_run( 'commit', [ '--file', $message_file, @$opts ] );

    # confirm temp file is removed
    undef $message_fh;
    if ( -s $message_file ) {
        warn "temp file not removed: $message_file";
    }

    # $ret is empty string on success. that's odd.
    if ( defined( $self->{stdout}->[0] )
        && $self->{stdout}->[-1] =~ m/Committed revision (\d+)/ )
    {
        return $1;
    }
    return 0;
}

=head2 status

Returns the workspace status of the object.

=cut

sub status {
    my $self = shift;
    $self->svn_run('status');

    if ( $self->is_dir ) {

        # find the arg that matches $self
        if ( defined $self->stdout->[0] ) {
            for my $line ( @{ $self->stdout } ) {
                if ( $line =~ m/^(\S)\s+\Q$self\E$/ ) {
                    return $1;
                }
            }
            return 0;
        }
    }

    if ( defined $self->stdout->[0] ) {
        my ($stat) = ( $self->stdout->[0] =~ m/^([A-Z\?])/ );
        return $stat;
    }
    return 0;
}

=head2 modified

Returns true if the status() of the object is C<Add> or C<Modified>.

=cut

sub modified {
    return $_[0]->status =~ m/^[MA]$/ ? 1 : 0;
}

=head2 conflicted

Returns true if the status() of the object is C<Conflicted>.

=cut

sub conflicted {
    return $_[0]->status eq 'C';
}

=head2 diff

Diff the workspace version of the object against either the repository
or the current working baseline version.

=cut

sub diff {
    shift->svn_run( 'diff', @_ );
}

=head2 blame

Annotated accounting of who modified what lines of the object.

=cut

sub blame {
    shift->svn_run( 'blame', @_ );
}

=head2 info

Returns SVN::Class::Info instance with information about the current
object or 0 on failure.

=cut

sub info {
    my $self = shift;
    return 0 unless $self->svn_run( 'info', @_ );
    return SVN::Class::Info->new( $self->stdout );
}

=head2 dump

Returns a Data::Dump serialization of the object. Useful for debugging.

=cut

sub dump {
    Data::Dump::dump(shift);
}

=head2 errstr

Returns the contents of error() as a newline-joined string.

=cut

sub errstr {
    my $self = shift;
    my $err  = $self->error;
    return ref($err) ? join( "\n", @$err ) : $err;
}

=head2 outstr

Returns the contents of stdout() as a newline-joined string.

=cut

sub outstr {
    my $self = shift;
    my $out  = $self->stdout;
    return ( ref($out) ? join( "\n", @$out ) : $out ) . "\n";
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svn-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Class>

=back

=head1 ACKNOWLEDGEMENTS

I looked at SVN::Agent before starting this project. It has
a different API, more like SVN::Client in the SVN::Core, but
I cribbed some of the ideas.

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2007 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Path::Class, Class::Accessor::Fast, SVN::Agent, IPC::Cmd
