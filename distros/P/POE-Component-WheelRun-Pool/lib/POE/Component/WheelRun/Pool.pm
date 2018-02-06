# ABSTRACT: POE::Wheel::Run worker pool
package POE::Component::WheelRun::Pool;

our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Const::Fast;
use Module::Load;
use POE qw(
    Filter::Reference
    Wheel::Run
);

const my @PASS_ARGS => qw(
    Program ProgramArgs
    Filter StdioFilter StdinFilter StdoutFilter StderrFilter
    Priority User Group NoSetSid NoSetPgrp
);



sub spawn {
    my $type = shift;

    # Arguments
    my %args = (
        Alias            => 'pool',
        PoolSize         => 4,
        MaxTasksPerChild => 0,
        MaxTimePerChild  => 0,
        Splay            => 0.1,
        ProgramArgs      => [],
        WorkerError      => undef,
        WorkerClose      => undef,
        WorkerSpawn      => undef,
        StdoutHandler    => undef,
        StderrHandler    => undef,
        StatsHandler     => undef,
        @_
    );

    unless ( exists $args{StdinFilter} or exists $args{StdoutFilter} ) {
        $args{StdioFilter} ||= POE::Filter::Reference->new();
    }

    # Validate the Program
    die "Must specify a Program argument as a coderef or path to a script."
        unless exists $args{Program};

    if(ref $args{Program} ne 'CODE') {
        if(!-x $args{Program}) {
            die "Program $args{Program} is not an executable.";
        }
    }

    my $session_id = POE::Session->create(
        inline_states => {
            # Internal
            _start              => \&pool_start,
            _stop               => \&pool_stop,
            _child              => \&pool_child,
            # Interface
            dispatch            => \&pool_dispatch,
            stats               => \&pool_stats,
            # Worker Management
            worker_spawn        => \&worker_spawn,
            worker_chld         => \&worker_chld,
            worker_error        => \&worker_error,
            worker_close        => \&worker_close,
            worker_stdout       => \&worker_stdout,
            worker_stderr       => \&worker_stderr,
        },
        heap => {
            replenish      => 0,
            args           => \%args,
            workers        => [],
            _workers       => {},
            _workers_pid   => {},
            current_worker => 0,
            expiry         => {},
            tasks          => {},
            stats          => { ticks => 0, },
        }
    );
}

sub pool_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my %args = %{ $heap->{args} };

    # Configure our alias
    $kernel->alias_set($args{Alias});

    # Configure Some Basics
    for ( 1 .. $args{PoolSize} ) {
        $kernel->call( $args{Alias} => 'worker_spawn');
    }

    # Check to make sure spawning happened successfully
    die "Failed starting the right number of workers" unless @{$heap->{workers}} == $args{PoolSize};

    # Enable auto-replenish
    $heap->{replenish} = 1;

    # Stats engine enabled
    $kernel->delay_add( stats => $args{StatsInterval} ) if exists $args{StatsInterval};
}

sub pool_child {
    my ($kernel,$heap,$reason,$child) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Record the Child Session Status
    my $stat = join('_', child => $reason );
    $heap->{stats}{$stat} ||= 0;
    $heap->{stats}{$stat}++;
}

sub pool_stop {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
}

sub pool_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $stats = delete $heap->{stats};
    if( defined $heap->{args}{StatsHandler} && ref $heap->{args}{StatsHandler} eq 'CODE' ) {
        eval {
            $heap->{args}{StatsHandler}->($stats);
        };
        if(my $error = $@) {
            # TODO: DEBUG("ERROR received processing stats: $error");
        }
    }
    $heap->{stats} = { ticks => $stats->{ticks} + 1 };
    $kernel->delay_add( stats => $heap->{args}{StatsInterval} );
}

sub pool_dispatch {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my @args = @_[ARG0..$#_];
    # Count dispatches
    $heap->{stats}{dispatched} ||= 0;
    $heap->{stats}{dispatched}++;

    # Reset processor back to 0
    $heap->{current_worker} = 0 if $heap->{current_worker} >= scalar @{ $heap->{workers} };

    # Dispatch to the child
    my $wid = $heap->{workers}[$heap->{current_worker}];
    $heap->{_workers}{$wid}->put(@args);
    $heap->{current_worker}++;

    # Check the worker lifespan if necessary
    my $shutdown_worker = 0;
    if( exists $heap->{expiry}{$wid} && time >= $heap->{expiry}{$wid} ) {
        $shutdown_worker = 1;
    }
    if( exists $heap->{tasks}{$wid} ) {
        $heap->{tasks}{$wid}--;
        if( $heap->{tasks}{$wid} <= 0 ) {
            $shutdown_worker = 1;
        }
    }
    if( $shutdown_worker == 1 ) {
        $heap->{stats}{expired} ||= 0;
        $heap->{stats}{expired}++;

        my $worker = _remove_worker($heap,$wid);
        if( defined $worker ) {
            $worker->shutdown_stdin;
            $worker->kill;
        }
        else {
            $heap->{stats}{expired_dead_worker} ||= 0;
            $heap->{stats}{expired_dead_worker}++;
        }
    }
}

sub worker_spawn {
    my($kernel,$heap,$dead_id) = @_[KERNEL,HEAP,ARG0];

    if( $dead_id && !$heap->{replenish} ) {
        # TODO: Error log/exception of some kind
        return undef;
    }

    # Pass the relevant options to the POE::Wheel::Run session
    my %wheel_args = ();
    foreach my $arg (@PASS_ARGS) {
        next unless exists $heap->{args}{$arg};
        $wheel_args{$arg} = $heap->{args}{$arg};
    }
    # Spawn the worker process
    my $worker = POE::Wheel::Run->new(
        CloseEvent   => 'worker_close',
        ErrorEvent   => 'worker_error',
        StdoutEvent  => 'worker_stdout',
        StderrEvent  => 'worker_stderr',
        %wheel_args,
    );
    if(!defined $worker) {
        $kernel->delay_add(worker_spawn => 5);
        return;
    }
    # Setup proper child reaping
    $kernel->sig_child($worker->PID, 'worker_chld');

    # Track Processors
    $heap->{_workers}{$worker->ID} = $worker;
    $heap->{_workers_pid}{$worker->PID} = $worker->ID;
    $heap->{workers} = [ sort { $a <=> $b } keys %{ $heap->{_workers} } ];
    $heap->{current_worker} = 0;
    $heap->{stats}{spawned} ||= 0;
    $heap->{stats}{spawned}++;

    # Assign affinity if we're able to
    my @cpus = ();
    eval {
        load Sys::CpuAffinity;

        $heap->{_max_cpu} ||= Sys::CpuAffinity::getNumCpus() - 1;
        die "no processor count established." unless $heap->{_max_cpu};

        # Assign Affinity
        for( 1..2 ) {
            $heap->{_cpu} = $heap->{_max_cpu} if $heap->{_cpu} < 0;
            push @cpus, $heap->{_cpu};
            $heap->{_cpu}--;
        }
        Sys::CpuAffinity::setAffinity($worker->PID, \@cpus);
        1;
    } or do {
        my $err = $@;
        $heap->{stats}{cpu_affinity_error} ||= 0;
        $heap->{stats}{cpu_affinity_error}++;
    };

    # Establish accounting for tasks/time
    foreach my $tracker (qw(expiry tasks)) {
        delete $heap->{$tracker}{$worker->ID} if exists $heap->{$tracker}{$worker->ID};
    }
    if( $heap->{args}{MaxTimePerChild} > 0 ) {
        my $adjuster = $heap->{args}{Splay} > 0 ? int(rand($heap->{args}{Splay}) * $heap->{args}{MaxTimePerChild} * (rand(1) > 0.5 ? -1 : 1))
                     : 0;
        $heap->{expiry} = time + $heap->{args}{MaxTimePerChild} + $adjuster;
    }
    if( $heap->{args}{MaxTasksPerChild} > 0 ) {
        my $adjuster = $heap->{args}{Splay} > 0 ? int(rand($heap->{args}{Splay}) * $heap->{args}{MaxTasksPerChild} * (rand(1) > 0.5 ? -1 : 1))
                     : 0;
        $heap->{tasks} = $heap->{args}{MaxTasksPerChild} + $adjuster;
    }

    # TODO: Log placeholder
    #INFO("proc_spawn_worker successfully spawned worker:" . $worker->ID . " (cpus:" . join(',', @cpus) . ")");
}
sub _remove_worker {
    my ($heap,$wid) = @_;

    return unless exists $heap->{_workers}{$wid};

    # Remove the Wheel from our HEAP
    my $worker = delete $heap->{_workers}{$wid};
    $heap->{workers} = [ sort { $a <=> $b } keys %{ $heap->{_workers} } ];

    return $worker;
}
sub worker_close {
    my ($kernel,$heap,$wid) = @_[KERNEL,HEAP,ARG0];

    _remove_worker($heap,$wid);
    $heap->{stats}{worker_close} ||= 0;
    $heap->{stats}{worker_close}++;
}
sub worker_chld {
    my ($kernel,$heap,$pid,$status) = @_[KERNEL,HEAP,ARG1,ARG2];

    my $wid = undef;
    if( ! exists $heap->{_workers_pid}{$pid} ) {
        $heap->{stats}{worker_chld_invalid} ||= 0;
        $heap->{stats}{worker_chld_invalid}++;
    }
    else {
        $wid = $heap->{_workers_pid}{$pid};
        _remove_worker($heap,$wid);
        $heap->{stats}{worker_chld} ||= 0;
        $heap->{stats}{worker_chld}++;
    }
    $kernel->yield( worker_spawn => $wid );
    $kernel->sig_handled();
}
sub worker_error {
    my ($kernel, $heap, $op, $code, $wid, $handle) = @_[KERNEL, HEAP, ARG0, ARG1, ARG3, ARG4];
    if ($op eq 'read' and $code == 0 and $handle eq 'STDOUT') {
        my $worker = _remove_worker($heap,$wid);
        if( defined $worker ) {
            $worker->shutdown_stdin;
            $worker->kill;
        }
        $heap->{stats}{worker_error} ||= 0;
        $heap->{stats}{worker_error}++;
    }
}
sub worker_stdout {
    my ($heap,@args) = @_[HEAP,ARG0..$#_];

    if( defined $heap->{args}{StdoutHandler} && ref $heap->{args}{StdoutHandler} eq 'CODE' ) {
        eval {
            $heap->{args}{StdoutHandler}->(@args);
        };
        if(my $error = $@) {
            warn $error;
            $heap->{stats}{worker_out_error} ||= 0;
            $heap->{stats}{worker_out_error}++;
        }
    }
    else {
        $heap->{stats}{worker_out_unhandled} ||= 0;
        $heap->{stats}{worker_out_unhandled}++;
    }
}
sub worker_stderr {
    my ($heap,@args) = @_[HEAP,ARG0..$#_];

    if( defined $heap->{args}{StderrHandler} && ref $heap->{args}{StderrHandler} eq 'CODE' ) {
        eval {
            $heap->{args}{StderrHandler}->(@args);
        };
        if(my $error = $@) {
            $heap->{stats}{worker_err_error} ||= 0;
            $heap->{stats}{worker_err_error}++;
        }
    }
    else {
        $heap->{stats}{worker_ste_unhandled} ||= 0;
        $heap->{stats}{worker_ste_unhandled}++;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::WheelRun::Pool - POE::Wheel::Run worker pool

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Provides a pool wrapper around POE::Wheel::Run to allow for large worker pools that are automatically replenished.
POE::Component::WheelRun::Pool uses STDIN, STDOUT, and STDERR for communication between the parent session and the worker children.

    my $worker_pool_id = POE::Component::WheelRun::Pool->spawn(
        Alias            => 'pool',             # Default
        Program          => \&run_analysis,     # Required
        PoolSize         => 4,                  # Default
        MaxTasksPerChild => 1000,               # Default '0' = unlimited
        MaxTimePerChild  => 3600,               # Default '0' = unlimited
        Splay            => 0.1,                # Default
        # Any Options from POE::Wheel::Run
        User     => 'bob',
        Group    => 'nobody',
        Priority => 5,
    );

    my $main = POE::Session->create(inline_states => {
        new_event => sub { $poe_kernel->post( pool => dispatch => @_[ARG0] ) },
    });

This will create a pool of 4 workers with the run_analyze function as the entry point to the pool::dispatch event.  Child processes
should monitor STDIN for availability as the first thing attempted by the parent is an EOF on the STDIN of the child to let it know it should
go away.  Failing this, a kill() is called which is SIGINT by default.

=head1 FUNCTIONS

=head2 spawn()

Creates the worker pool and sets it ready for incoming tasks.
POE::Component::WheelRun::Pool will pass sensible options from POE::Wheel::Run
to the child process.  See:

    perldoc POE::Wheel::Run

For more information on options not covered here.

=over 8

=item B<Alias>

Default is 'pool', use a unique name to make dispatching events to worker pools easier to understand.

=item B<Program>

Required! Can be either a CODE reference or a path to an executable to launch.  The script needs to be able to accept data on STDIN and communicate
back to the parent session using STDOUT or STDERR.  This means the program can be in any language.

=item B<PoolSize>

Default is 4.  This is the number of children to spawn and maintain.

=item B<MaxTasksPerChild>

Default 0, anything <= 0 means unlimited.  This is the maximum number of tasks that can be handed to any one worker before it needs to respawn.

=item B<MaxTimePerChild>

Default 0, anything <= 0 means unlimited.  This is the maximum number of seconds any worker can live before being killed and respawned.  This check occurs only inside of the
dispatch event trigger and only for that "next" worker.   This means it is possible for processes to live longer that B<MaxTimePerChild>, but their next invocation will
be their last.

=item B<Splay>

Default is 0.1 and is unimportant without B<MaxTimePerChild> or B<MaxTasksPerChild>.  This applies a random splay to the time or tasks checker.  Best thought of as a percentage
range for max tasks or time.  e. g.

    ChildMaxUpperBound = MaxTasksPerChild + (Splay * MaxTasksPerChild)
    ChildMaxLowerBound = MaxTasksPerChild - (Splay * MaxTasksPerChild)

When a child is spawned the max tasks/time is calculated inside that range using two calls to rand(), one for the B<Splay> and the second for positive/negative.

The idea behind this is to offset process creation in the parent process as that can be expensive.  If you would like to disable this feature, set the B<Splay> to B<0>.

=item B<StatsInterval>

Default is 60.  Seconds to run the stats handler.

=item B<StatsHandler>

Default 'undef'.  If passed a CODE reference, that refernce is run every B<StatInterval> seconds. The handler is passed a hash reference with the events tracked and the values
representing the number of times each event ocurred.

=item B<StdoutHandler>

Default 'undef'.  CODE reference with what to do when there's content on STDOUT of the worker process.  Based on B<StdioFilter> or B<StdoutFilter> this reference may be passed
the content as a stream, line of text, or even a Perl object.

=item B<StderrHandler>

Default 'undef'.  CODE reference with what to do when there's content on STDERR of the worker process.  Based on B<StderrFilter> this reference may be passed
the content as a stream, line of text, or even a Perl object.

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/POE-Component-WheelRun-Pool>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-WheelRun-Pool>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/POE-Component-WheelRun-Pool>

=cut
