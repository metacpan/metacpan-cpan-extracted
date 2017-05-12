package Sys::RunUntil;

$VERSION= '0.04';

# be as strict as possible
use strict;

# constants we need
use constant SIGALIVE =>  0;
use constant SIGINFO  => 29;
use constant SIGTERM  => 15;

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl functionality
#
#-------------------------------------------------------------------------------
# import
#
# Called during execution of "use"
#
#  IN: 1 class
#      2 runtime of script

sub import {
    my ( undef, $runtime )= @_;

    # huh?
    die "Must specify a time until which the script should run\n"
      if !defined $runtime;

    # set CPU flag
    my $cpu= ( $runtime =~ s#[cC]## );
    $cpu= undef if $runtime =~ s#[wW]##;

    # huh?
    die "Unrecognizable runtime specified: $runtime\n"
      if $runtime !~ m#^[sSmMhHdD\d]+$#;

    # calculate number of seconds
    my $seconds= 0;
    $seconds += $1             if $runtime =~ m#(\d+)[sS]?#;
    $seconds += ( 60 * $1 )    if $runtime =~ m#(\d+)[mM]#;
    $seconds += ( 3600 * $1 )  if $runtime =~ m#(\+?\d+)[hH]#;
    $seconds += ( 86400 * $1 ) if $runtime =~ m#(\+?\d+)[dD]#;

    # only allowing so much CPU
    if ($cpu) {

        # set up pipe to child
        pipe my $child, my $parent;
        my $pid= fork();
        die "Could not fork: $!\n" unless defined $pid;
        
        # in child, make sure we will flush
        if ( !$pid ) {
            close $child;
            require IO::Handle;
            $parent->autoflush;

            # install signal handler for fetching information
            $SIG{INFO}= sub {
                my @time= times;
                my $time= $time[0] + $time[1] + $time[2] + $time[3];
                printf $parent "%.0f\n",$time;
            };

            # let the child process do its thing
            return;
        }        

        # exit parent process whenever child exits
        $SIG{CHLD}= sub { exit };

        # set up for reading
        close $parent;
        my $rbits;
        vec( $rbits, fileno( $child), 1 )= 1;

        # while not all CPU has been burnt
        my $burnt= 0;
        while ( $burnt < $seconds ) {
            sleep $seconds - $burnt;

            # what are you doing?
            kill SIGINFO, $pid;
            until ( select $rbits, undef, undef, 1 ) {
                exit if kill SIGALIVE, $pid;
            }

            # child gone
            exit if !defined( $burnt= readline $child );
        }

        # child has overstayed its welcome
        kill SIGTERM, $pid;
        exit;
    }

    # only interested in wallclock
    else {
        my $pid= fork();
        die "Could not fork: $!\n" if !defined $pid;

        # we're in the child, do what you want to do
        return if !$pid;  

        # set up alarm handler that will kill child
        $SIG{ALRM}= sub {
            kill SIGTERM, $pid;
            exit 1;
        };

        # wait for the child
        alarm $seconds;
        wait;

        # we're done
        exit;
    }
} #import

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Sys::RunUntil - make sure script only runs for the given time

=head1 VERSION

This documentation describes version 0.04.

=head1 SYNOPSIS

 use Sys::RunUntil '30mW';
 # code which may only take 30 minutes to run

 use Sys::RunUntil '30sC';
 # code which may only take 30 seconds of CPU time

=head1 DESCRIPTION

Provide a simple way to make sure the script from which this module is
loaded, is running only for either the given wallclock time or a maximum
amount of CPU time.

=head1 METHODS

There are no methods.

=head2 RUNTIME SPECIFICATION

The maximum runtime of the script can be specified in seconds, or with any
combination of the following postfixes:

 - S seconds
 - M minutes
 - H hours
 - D days

The string "1H30M" would therefor indicate a runtime of 5400 seconds.

The letter B<C> indicates that the runtime is specified in CPU seconds used.
The (optional) letter B<W> indicates that the runtime is specified in wallclock
time.

=head1 THEORY OF OPERATION

The functionality of this module basically depends on C<alarm> and C<fork>,
with some pipes and selects mixed in when checking for CPU time.

=head2 Wallclock Time

When the "import" class method is called (which happens automatically with
C<use>), that method forks the process and sets an C<alarm> in the parent
process and waits for the child process to return.  If the process returns
before the C<alarm> is activated, that's ok.  If the C<alarm> is triggered,
it means that the child process is taking to long: the parent process will
then kill the child by sending it a TERM (15) signal and exit.

=head2 CPU time

When the "import" class method is called (which happens automatically with
C<use>), that method creates a pipe and forks the process.  In the child
process a signal handler is installed on the C<INFO> (29) signal which prints
the total CPU time used on the pipe to the parent.  The parent then waits
for the minimum amount of time that would need to expire before the CPU limit
in the child process is reached.  It then sends the INFO signal to the child
process to obtain the amount of CPU used by the child.  The parent then
decides to wait longer or to kill the child process by sending it a C<TERM>
(15) signal.

=head1 REQUIRED MODULES

 (none)

=head1 SEE ALSO

L<Sys::RunAlone>, L<Sys::RunAlways>.

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2005, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
