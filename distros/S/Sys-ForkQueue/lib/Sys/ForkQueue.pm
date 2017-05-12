package Sys::ForkQueue;
{
  $Sys::ForkQueue::VERSION = '0.14';
}
BEGIN {
  $Sys::ForkQueue::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Run any number of jobs in a controlled manner in parallel.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

# for fork()
use Errno qw(EAGAIN);
use POSIX qw(WNOHANG SIGTERM);
use Sys::CPU;

# DGR: we'll it's ugly but that's the way fork() works in perl ...
## no critic (ProhibitPackageVars)
# for fork control
our $zombies = 0;
our %Kid_Status;
our %childs_running = ();
## use critic
## no critic (RequireLocalizedPunctuationVars)
$SIG{CHLD} = sub { $zombies++ };
$SIG{INT}  = \&_sigterm;
$SIG{TERM} = \&_sigterm;
## use critic

has 'chdir' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 0,
);

has 'umask' => (
    'is'        => 'rw',
    'isa'       => 'Str',
    'default'   => 0,
);

has 'jobs' => (
    'is'       => 'ro',
    'isa'      => 'ArrayRef[Str]',
    'required' => 1,
);

has '_job_status' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Int]',
    'default' => sub { {} },
);

has 'code' => (
    'is'       => 'ro',
    'isa'      => 'CodeRef',
    'required' => 1,
);

has 'args' => (
    'is'      => 'rw',
    'isa'     => 'HashRef',
    'default' => sub { {} },
);

has 'concurrency' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'lazy'    => 1,
    'builder' => '_num_cores',
);

has 'redirect_output' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'chdir' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 0,
);

has 'setsid' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'delayedfork' => (
    'is'    => 'rw',
    'isa'   => 'Bool',
    'default' => 1,
);

with qw(Log::Tree::RequiredLogger);

sub _num_cores {
    my $self = shift;

    return Sys::CPU::cpu_count() || 1;
}

sub run {
    my $self = shift;

    # Loop control
    my $concurrency     = $self->concurrency();    # 0 means inifite num. of forks
    my $forks_running   = 0;
    my $childs_returned = 0;
    my $ok              = 1;

  JOB: foreach my $job ( @{ $self->jobs() } ) {

        while ( $concurrency && $forks_running >= $concurrency ) {

            # wait until there is a free slot to run
            ## no critic (ProhibitSleepViaSelect)
            select undef, undef, undef, 0.2;
            ## use critic
            if ($zombies) {
                my $reaped = $self->_reaper();
                $childs_returned += $reaped if $reaped;
                $forks_running = $forks_running - $reaped if $reaped;
            }
        }
        if ( !$concurrency || $forks_running < $concurrency ) {
            $self->logger->log( message => "Creating fork for Job: $job", level => 'debug', );

            # fork() - see Programming Perl p. 737
          FORK:
            {
                if ( my $pid = fork ) {

                    # This is the parent process, child pid is in $pid
                    $forks_running++;
                    $childs_running{$pid} = 1;
                    ## no critic (ProhibitSleepViaSelect)
                    select undef, undef, undef, 0.1 if $self->delayedfork();
                    ## use critic
                }
                elsif ( defined $pid ) {

                    # prevent the possibility to acquire a controlling terminal
                    $SIG{'HUP'} = 'IGNORE';

                    # bring Logger in a suitable state
                    # this will at least clear the internal logging buffer, other tasks may be performed as well depending on
                    # the implementation of the Logger
                    $self->logger()->forked();

                    if ( $self->setsid() ) {
                        $self->logger()->log( message => 'Calling setsid', level => 'debug', );
                        POSIX::setsid()    # create own process group
                    }
                    if ( $self->chdir() && -d $self->chdir() ) {
                        $self->logger()->log( message => 'Changing work dir to ' . $self->chdir(), level => 'debug', );
                        chdir( $self->chdir() );
                    }
                    elsif ( $self->chdir() ) {
                        $self->logger()->log( message => 'Changing work dir to /.', level => 'debug', );
                        chdir(q{/});
                    }

                    # clear the file creation mask
                    umask $self->umask();
                    ## no critic (RequireCheckedClose)
                    close(STDIN);
                    if ( $self->redirect_output() ) {
                        $self->logger()->log( message => 'Redirecting output to ' . $self->redirect_output(), level => 'debug', );
                        close(STDOUT);
                        close(STDERR);
                    }
                    ## use critic
                    ## no critic (RequireCheckedOpen)
                    open( STDIN, '<', '/dev/null' );
                    if ( $self->redirect_output() ) {
                        open( STDOUT, '>>', $self->redirect_output() . q{.} . $job );
                        open( STDERR, '>>', $self->redirect_output() . q{.} . $job );
                    }
                    ## use critic

                    # $pid is null, if defined
                    # This is the child process
                    # get the pid of the parent via getppid
                    my $pid  = $$;
                    my $ppid = getppid();
                    $self->logger()->prefix('[CHILD '.$job.q{ }.$pid.q{/}.$ppid.']');

                    $self->logger->log( message => 'Fork for Job '.$job.' running ...', level => 'debug', );

                    my $t0     = time();                                      # starttime
                    my $status = &{ $self->code() }( $job, $self->args() );
                    my $d0     = time() - $t0;                                # duration
                    if ($status) {
                        $self->logger->log( message => 'Fork finished with SUCCESS after running for ' . $d0 . 's.', level => 'debug', );
                        exit 0;
                    }
                    else {
                        $self->logger->log( message => 'Fork finished with FAILURE after running ' . $d0 . 's.', level => 'warning', );
                        exit 1;
                    }

                    # end of fork(). The child _must_ exit here!
                }
                elsif ( $! == EAGAIN ) {

                    # EAGAIN, probably temporary fork error
                    sleep 5;
                    redo FORK;
                }
                else {

                    # Strange fork error
                    warn 'Can not exec fork: '.$!."\n";
                }
            }    # FORK
        }    # if-forks-running-lt-concurrency
        else {
            $self->logger->log( message => 'Too many childs to spawn a new one (Running: '.$forks_running.' / Max: '.$concurrency.')', level => 'debug', );
            sleep 1;
            redo JOB;
        }
    }    # end of foreach jobs
    $self->logger()->log( message => 'Dispatched all childs. Waiting for them to finish ...', level => 'debug', );
    my $child;
    while ( ( $child = waitpid( -1, 0 ) ) > 0 ) {
        $self->_job_status()->{$child} = $? >> 8;
        delete( $childs_running{$child} );
        $childs_returned++;
        if ( $self->_job_status()->{$child} != 0 ) {
            $ok = 0;
        }
    }
    $self->logger()->log( message => '[PARENT] Collected all child stati.', level => 'debug', );
    $self->logger()->prefix(q{});
    if ($ok) {
        $self->logger()->log( message => 'All childs returned w/o error', level => 'debug', );
        return 1;
    }
    else {
        $self->logger()->log( message => 'Some childs returned an error', level => 'error', );
        return;
    }
}

############################################
# Usage      : none, called by $SIG{CHLD}
# Purpose    : Collect zombies
# Returns    : Number of zombies collected
# Parameters : none
# Throws     : no exceptions
# Comments   : none
# See Also   : Programming Perl, p. 432
sub _reaper {
    my $self = shift;

    $zombies = 0;
    my $childs_finished = 0;
    my $child;
    while ( ( $child = waitpid( -1, WNOHANG ) ) > 0 ) {
        $self->_job_status()->{$child} = $? >> 8;
        delete( $childs_running{$child} );
        $childs_finished++;
    }
    return $childs_finished;
}

sub _sigterm {
    #print "Received SIGTERM. Aborting running forks ...\n";

    # kill childs - kill(TERM, -$$):
    my $cnt = kill( SIGTERM, q{-} . $$ );
    say 'Signaled '.$cnt.' processes in current processgroup';
    foreach my $child_pid ( keys %childs_running ) {
        next unless $child_pid;
        kill( SIGTERM, $child_pid );
        say 'Signaled '.$child_pid;
    }

    # die
    exit;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::ForkQueue - Run any number of jobs in a controlled manner in parallel.

=head1 SYNOPSIS

        use Sys::ForkQueue;
        my @jobs = qw(1 2 3 4 5 6 7 8 9 10);
        my $Queue = Sys::ForkQueue::->new({
                'jobs' => \@jobs,
                'code' => \&worker,
                'logger' => Log::Tree::->new(),
        });
        $Queue->run();

        sub worker { ... }

=head1 DESCRIPTION

This class implements a job controller that can run any number of
jobs with configurable parllelism.

=head1 ATTRIBUTES

=head2 chdir

Change to this directory after fork.

If the given directory does not exist, change to /.

=head2 umask

Set this umask after fork.

=head2 jobs

Must contain a list of job names. Each will be passed
to the CODEREF in $self->code() when it's runnable.

=head2 code

The CODEREF. This will called for every job in the list.
Ths first argument will be the job name. The second one
will be $self->args() which is an hashref.

=head2 args

This will be passed to every invocation of $self->code().

=head2 concurrency

Run this many jobs in parallel.

=head2 redirect_output

Redirect all output to this file.

=head2 chdir

Change to this directory after fork()ing.

=head2 setsid

Call setsid after fork().

=head2 delayedfork

Sleep for a brief time after fork. Set this to false
if you plan to run many short lived jobs.

=head1 NAME

Sys::ForkQueue - Run any number of jobs in a controlled manner in parallel.

=head1 SUBROUTINES/METHODS

=head2 run

Run all enqueud jobs.

=head2 EAGAIN

Imported from Errno.

=head2 SIGTERM

Imported from POSIX.

=head2 WNOHANG

Imported from POSIX.

1; # End of Sys::ForkQueue

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
