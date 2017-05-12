package Spawn::Safe;

use strict;
use IO::Select;
use POSIX ":sys_wait_h";
use Carp qw/croak/;

# Based off of the smallest PIPE_BUF I've seen.
use constant PIPE_BUF_SIZE => 512;

use vars qw( $VERSION );
$VERSION = '2.006';

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );

    @ISA    = qw(Exporter);
    @EXPORT = qw/ spawn_safe /;
}

=head1 NAME

Spawn::Safe - Fork and exec a process "safely".

=head1 EXAMPLE

A basic example:

 use Spawn::Safe;
 use Data::Dumper;
 my $results = spawn_safe({ argv => [ 'ls', '-al', '/var/' ], timeout => 2 });
 die Dumper $results;

As a replacement for backticks:

 use Spawn::Safe;
 # $output = `ls -al /var/`;
 $output = spawn_safe(qw{ ls -al /var/ })->{stdout};

=head1 SYNOPSIS

Spawn::Safe is a module designed to make "safe" calls to outside binaries
easier and more reliable. Spawn::Safe never invokes a shell (unless the shell
is explicitly requested), so escaping for the shell is not a concern. An
optional timeout is made available, so scripts will not hang forever, and the
caller is able to retrieve both stdout and stderr. An optional string can be
passed to the executed program's standard input stream.

=head1 FUNCTIONS

=head2 spawn_safe

Spawn (via fork and exec) the specified binary and capture its output.

=head3 Parameters

If passed a single scalar, spawn_safe will assume that to be the the target
binary, and execute it without a limit on runtime.

If passed an array, spawn_safe will execute the first element of the array as
the target binary, with the remaining elements passed as parameters to the
target binary, without a limit on runtime.

The preferred mode is to pass in a single hash reference. When called this
way, the following keys are available:

=over 4

=item * argv

Either a string containing the name of the binary which will be called with no
parameters:

 my $r = spawn_safe({ argv => 'ls' });

Or an array reference containing the binary and all of its parameters:

 my $r = spawn_safe({ argv => [ 'ls', '-al' ] });

=item * timeout

The amount of time, in seconds, the binary will be allowed to run before being
killed and a timeout error being returned. If false (or is otherwise undefined
or unset), the timeout will be infinite.

=item * env

A hash reference containing the new environment for the executed binary. If
false (or otherwise undefined or unset), it will default to the current
environment. You must specify the complete environment, as the current
environment will be overwritten as a whole. To alter only one variable, a copy
of the enviornment must be made, altered, and then passed in as a whole, eg:

 my %new_env = %ENV;
 $new_env{'TMP'} = '/var/tmp/';
 my $r = spawn_safe({ argv => 'ls', env => \%new_env });

Please note that if a new environment is specified, the new binary's
environment will be altered before the call to exec() (but after the fork(),
so the caller's environment will be unchanged), so the new environment will
take effect before the new binary is launched. This means that if you alter a
part of the environment needed to launch the binary (eg, by changing PATH,
LD_LIBRARY_PATH, etc), these new variables will need to be set such that the
binary can be executed successfully.

=item * stdin

A string to be passed to the target binary's standard input stream. The string
will be written into the stream and then the stream will be closed.

 my $r = spawn_safe({ argv => [ '/usr/bin/tr', 'a', 'b' ], stdin => 'aaa' });

=back

=head3 Return value

A hash reference will be returned containing one of the following sets of
values:

=over 4

=item * If the binary could not be spawned, the single key, 'error' will be
set, which is a text description of the reason the binary could not be spawned.

=item * If the binary was executed successfully, but terminated due to a
timeout, the keys 'error', 'stdout', and 'stderr', will be set. The value for
'error' will be set to 'timed out'. Any data collected from the executed
binary's stdout or stderr will also be made available, but since the binary was
forcefully terminated, the data may be incomplete.

=item * If the binary was executed successfully and ran to completion, the keys
'exit_code', 'stdout, and 'stderr', will all be available.

=back

The key "exit_zero" will always be present, which is true if the binary is
executed successfully and exited with a code of zero.

=head3 Notes

The current PATH will be searched for the binary, if available. Open
filehandles are subject to Perl's standard close-on-exec behavior. A shell will
not be invoked unless explicitly defined as the target binary, as such output
redirection and other shell features are unavailable.

If passed invalid parameters, spawn_safe will croak.

Please note that when specifying a timeout, alarm() is no longer used. If the
clock is stepped significantly backwards during a timeout, a possibly false
timeout error may be thrown. Timeout accuracy should be within one second.

If a timeout does occur, the spawned program will be sent a SIGKILL before
spawn_safe returns.

=head1 COMPATIBILITY

This module attempts to work on MSWin32 but I've been unable to get it working
due to strange issues with IO::Select. I haven't been able to track down the
exact cause, so for now I don't believe this module functions on MSWin32.

Linux and BSD are tested and supported platforms.

=cut

sub spawn_safe {
    my ( $params ) = @_;
    my @binary_and_params;
    my $timeout;
    my $start_time;
    my $new_env;
    my $for_stdin;
    my $for_stdin_offset = 0;

    if ( ref $params eq '' ) {
        @binary_and_params = @_;
    } elsif ( ref $params eq 'HASH' ) {
        if ( !$params->{'argv'} ) {
            croak "Invalid parameters (missing argv)";
        }
        if ( ref $params->{'argv'} eq 'ARRAY' ) {
            @binary_and_params = @{ $params->{'argv'} };
        } elsif ( ref $params->{'argv'} eq '' ) {
            @binary_and_params = $params->{'argv'};
        } else {
            croak "Invalid parameters (what is argv?)";
        }

        if ( ref $params->{'env'} eq 'HASH' ) {
            $new_env = $params->{'env'};
        }

        $timeout   = $params->{'timeout'} || undef;
        $for_stdin = $params->{'stdin'}   || undef;
    } else {
        croak "Invalid parameters";
    }

    my ( $child_pid,          $exit_code );
    my ( $parent_read_stdout, $child_write_stdout );
    my ( $parent_read_stderr, $child_write_stderr );
    my ( $parent_signal,      $child_wait );
    my ( $parent_read_errors, $child_write_errors );
    my ( $child_read_stdin,   $parent_write_stdin );

    my ( $read_stdout, $read_stderr, $read_errors ) = ( '' ) x 3;

    pipe( $parent_read_stdout, $child_write_stdout ) || die $!;
    pipe( $parent_read_stderr, $child_write_stderr ) || die $!;
    pipe( $parent_read_errors, $child_write_errors ) || die $!;
    pipe( $child_read_stdin,   $parent_write_stdin ) || die $!;
    pipe( $child_wait,         $parent_signal )      || die $!;

    $child_pid = fork();
    if ( !defined $child_pid ) {
        die "Unable to fork: $!";
    }

    if ( !$child_pid ) {
        close( $parent_signal );
        close( $parent_read_stdout );
        close( $parent_read_stderr );
        close( $parent_read_errors );
        close( $parent_write_stdin );

        if ( tied( *STDIN ) )  { untie *STDIN; }
        if ( tied( *STDOUT ) ) { untie *STDOUT; }
        if ( tied( *STDERR ) ) { untie *STDERR; }

        # Be 5.6 compatible and do it the old way.
        open( STDOUT, '>&' . fileno( $child_write_stdout ) ) || goto CHILD_ERR;
        open( STDERR, '>&' . fileno( $child_write_stderr ) ) || goto CHILD_ERR;
        open( STDIN,  '<&' . fileno( $child_read_stdin ) )   || goto CHILD_ERR;

        if ( $new_env ) { %ENV = %{$new_env}; }

        <$child_wait>;
        close( $child_wait );

        { exec { $binary_and_params[0] } @binary_and_params; }
       CHILD_ERR:
        print $child_write_errors $!;
        close( $child_write_errors );
        close( $child_write_stdout );
        close( $child_write_stderr );

        # Exit code here isn't actually used.
        exit 42;
    }

    close( $child_write_stdout );
    close( $child_write_stderr );
    close( $child_read_stdin );
    close( $child_wait );
    close( $child_write_errors );
    my $sel = IO::Select->new( $parent_read_stdout, $parent_read_stderr, $parent_read_errors )
     || die "Failed to create IO::Select object!";
    my $wsel;

    if ( defined $for_stdin ) {
        $wsel = IO::Select->new( $parent_write_stdin )
         || die "Failed to create IO::Select object!";
    } else {
        close( $parent_write_stdin );
    }
    close( $parent_signal );

    # Don't bother calling time if we're never going to timeout.
    $start_time = defined $timeout ? time() : 1;
    my $select_time = $timeout;
   MAIN_WHILE: while ( 1 ) {
        my ( $readus, $writeus, undef ) = IO::Select::select( $sel, $wsel, undef, $select_time );
        if ( ref $readus eq 'ARRAY' ) {
            foreach my $readme ( @{$readus} ) {
                my $read;
                my $r = sysread( $readme, $read, PIPE_BUF_SIZE );
                if ( ( !defined $r ) || ( $r < 1 ) ) {
                    $sel->remove( $readme );
                    if ( $sel->count() == 0 ) { last MAIN_WHILE; }
                } elsif ( $readme == $parent_read_stdout ) {
                    $read_stdout .= $read;
                } elsif ( $readme == $parent_read_stderr ) {
                    $read_stderr .= $read;
                } elsif ( $readme == $parent_read_errors ) {
                    $read_errors .= $read;
                } else {
                    die 'Should not be here!';
                }
            }
        }
        if ( ref $writeus eq 'ARRAY' ) {
            foreach my $writeme ( @{$writeus} ) {
                if ( $writeme == $parent_write_stdin ) {
                    my $write_size = PIPE_BUF_SIZE <= length( $for_stdin ) ? PIPE_BUF_SIZE : length( $for_stdin );
                    syswrite( $parent_write_stdin, $for_stdin, $write_size, $for_stdin_offset );
                    $for_stdin_offset += $write_size;
                    if ( $for_stdin_offset >= length( $for_stdin ) ) {
                        $wsel->remove( $parent_write_stdin );
                        close( $parent_write_stdin );
                    }
                }
            }
        }
        if ( defined $timeout ) {
            # We do a little gymnastics here to check if the time has rolled
            # backwards (ie, ntpd stepped the time backwards). If it went
            # backwards, there's no way to tell how long we've waited, so
            # it's probably safer to assume we've waited too long. Hopefully
            # steps backwards will be infrequent, as ntpd usually slews rather
            # than steps.
            # If the time rolls over, we should end up with a hugely negative
            # $timeout after subtraction, so that will probably trigger a
            # timeout as well. Imperfect, but somewhat better than waiting
            # forever. Fortunately this probably won't ever come up.
            my $timenow = time();
            $select_time = $timeout - ( $timenow - $start_time );
            if ( $timenow < $start_time || $select_time <= 0 ) {
                undef $start_time;
                last;
            }
        }
    }
    # Did we timeout? undef $start_time is our timeout flag.
    if ( defined $start_time ) {
        waitpid( $child_pid, 0 );
        $exit_code = $? >> 8;
    }

    close( $parent_read_stdout );
    close( $parent_read_stderr );
    close( $parent_read_errors );

    if ( !defined $start_time ) {
        # If the child is still running, kill it.
        if ( waitpid( $child_pid, WNOHANG ) != -1 ) {
            kill( 9, $child_pid );
            waitpid( $child_pid, 0 );
        }

        return {
            'error'     => 'timed out',
            'stdout'    => $read_stdout,
            'stderr'    => $read_stderr,
            'exit_zero' => 0,
        };
    }

    if ( $read_errors ) {
        return {
            'error'     => $read_errors,
            'exit_zero' => 0,
        };
    }
    return {
        'exit_code' => $exit_code,
        'stdout'    => $read_stdout,
        'stderr'    => $read_stderr,
        'exit_zero' => $exit_code == 0,
    };
}

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 CHANGES

=head2 Version 2.006 - 2013-11-12, jeagle

Modify PIPE_BUF_SIZE to be more conservative to ensure non-blocking writes on
all OSs.

=head2 Version 2.005 - 2013-11-11, jeagle

Add stdin option, clarify docs, add exit_zero return flag.

=head2 Version 2.004 - 2012-08-13, jeagle

Include license. Oops.

=head2 Version 2.003 - 2012-04-01, jeagle

Untie any tied filehandles before we re-open them to ourselves to work around
any weird tie behavior (should fix issues running under FCGI). Thanks Charly.

=head2 Version 2.002 - 2012-01-04, jeagle

Correct documentation (RT#72831, thanks Stas)

Update unit tests to specify number of tests instead of using no_plan,
otherwse CPAN Testers reports tests fail.

=head2 Version 2.001 - 2011-06-13, jeagle

Give the spawned program its own STDIN.

=head2 Version 2.000 - 2011-05-12, jeagle

Correct timeout handling. Attempt to correct unit tests for MSWin32, but
there seems to be an issue with IO::Select preventing it from working
properly. Update docs for MSWin32.

=head2 Version 1.9 - 2011-05-10, jeagle

Don't use clock_gettime(), use time() and return a timeout if time steps
backwards.

=head2 Version 1.8 - 2011-05-09, jeagle

Clean up docs, stop using SIGALARM for timeouts.

=head2 Version 1.7 - 2010-07-09, jeagle

Clean up for release to CPAN.

=head2 Version 0.4 - 2009-05-13, jeagle

Correct a warning issued when using spawn_safe without a timeout.

Fix compatibility with perl < 5.8.

=head2 Version 0.3 - 2009-04-21, jeagle

Clarify documentation regarding use of SIGALRM and for passing of a new
environment.

Correct a warning thrown by exec().

Correct an issue with incorrectly handled timeouts.

=head2 Version 0.2 - 2009-04-20, jeagle

Modify API, breaking compatibility, for clarity and expandability.

Add the ability to specify the target program's environment.

Return the (partial) stdout and stderr on a timeout.

Update and clarify documentation.

=head2 Version 0.1 - 2009-04-11, jeagle

Inital release.

=cut

1;
