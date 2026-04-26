package Parallel::Subs;
$Parallel::Subs::VERSION = '0.003';
use strict;
use warnings;

use Carp qw(croak);
use Parallel::ForkManager;
use Scalar::Util qw(weaken);


# ABSTRACT: Simple way to run subs in parallel and process their return value in perl


sub new {
    my ( $class, %opts ) = @_;

    my $self = bless {}, __PACKAGE__;

    $self->_init(%opts);

    return $self;
}

sub _init {
    my ( $self, %opts ) = @_;

    $self->_pfork(%opts);
    $self->{timeout}  = $opts{timeout};
    $self->{result}   = {};
    $self->{failures} = [];

    # Use a weak reference to break the circular reference:
    # $self -> {pfork} -> run_on_finish closure -> $self
    my $weak_self = $self;
    weaken($weak_self);

    $self->{pfork}->run_on_finish(
        sub {
            my ( $pid, $exit, $id, $exit_signal, $core_dump, $data ) = @_;
            return unless $weak_self;
            if ( $exit || $exit_signal ) {
                my $error = ( $data && $data->{error} ) ? $data->{error} : undef;
                push @{ $weak_self->{failures} }, {
                    id     => $id,
                    pid    => $pid,
                    exit   => $exit,
                    signal => $exit_signal,
                    error  => $error,
                };
            }
            else {
                $weak_self->{result}->{$id} = $data->{result};

                # Fire callback immediately as each job completes
                my $cb = $weak_self->{callbacks}[ $id - 1 ];
                if ( $cb && ref $cb eq 'CODE' ) {
                    $cb->( $data->{result} );
                }
            }
        }
    );
    $self->{jobs}      = [];
    $self->{callbacks} = [];
    $self->{named}     = {};

    return $self;
}

sub _pfork {
    my ( $self, %opts ) = @_;

    for my $opt (qw(max_process max_process_per_cpu max_memory timeout)) {
        croak "$opt must be a positive number"
          if defined $opts{$opt} && $opts{$opt} <= 0;
    }

    my $cpu;
    if ( defined $opts{max_process} ) {
        $cpu = $opts{max_process};
    }
    else {
        my $factor = $opts{max_process_per_cpu} || 1;
        eval {
            require Sys::Info;
            $cpu = Sys::Info->new()->device('CPU')->count() * $factor;
        };
    }
    if ( defined $opts{max_memory} ) {
        my $free_mem;
        eval {
            require Sys::Statistics::Linux::MemStats;
            $free_mem = Sys::Statistics::Linux::MemStats->new->get->{realfree};
        };
        my $max_mem = $opts{max_memory} * 1024;  # express in Kb
        my $cpu_for_mem;
        if ($@) {
            warn "max_memory option requires Sys::Statistics::Linux::MemStats "
              . "(Linux only); falling back to max_process=2 on this platform\n";
            $cpu_for_mem = 2;
        }
        else {
            $cpu_for_mem = int( $free_mem / $max_mem );
        }

        $cpu = $cpu_for_mem if !defined $cpu || $cpu_for_mem < $cpu;
    }
    $cpu ||= 1;

    $self->{cpu} = $cpu;

    # we could also set a minimum amount of required memory
    $self->{pfork} = Parallel::ForkManager->new( int($cpu) );
    $self->{pfork}->set_waitpid_blocking_sleep(0)
      unless $opts{waitpid_blocking_sleep};

    return $self;
}


sub add {
    my $self = shift;

    # Optional name as first argument (non-reference string)
    my $user_name;
    if ( @_ >= 2 && defined $_[0] && !ref $_[0] ) {
        $user_name = shift;
    }

    my ( $code, $callback ) = @_;

    croak "add() requires a CODE reference as first argument"
      unless $code && ref $code eq 'CODE';
    croak "callback must be a CODE reference"
      if defined $callback && ref $callback ne 'CODE';

    if ( defined $user_name ) {
        croak "duplicate job name '$user_name'"
          if exists $self->{named}{$user_name};
    }

    my $position = scalar( @{ $self->{jobs} } ) + 1;
    push(
        @{ $self->{jobs} },
        { name => $position, code => $code }
    );
    push( @{ $self->{callbacks} }, $callback );

    if ( defined $user_name ) {
        $self->{named}{$user_name} = $position;
    }

    return $self;
}


sub total_jobs {
    my ($self) = @_;

    return scalar @{ $self->{jobs} };
}


sub wait_for_all_optimized {
    my ($self) = @_;

    return $self unless $self->total_jobs;
    my @original_jobs = @{ $self->{jobs} };

    # callback not supported for now
    if ( scalar @{ $self->{callbacks} } ) {
        warn "Callback not supported in this mode for now.\n"
          if grep { defined $_ } @{ $self->{callbacks} };
        $self->{callbacks} = [];
    }

    my $cpu = $self->{cpu} or die;
    my $jobs_per_cpu = int( scalar @original_jobs / $cpu );
    ++$jobs_per_cpu if scalar @original_jobs % $cpu || !$jobs_per_cpu;

    my @new_jobs;

    my $generate_sub = sub {
        my ( $from, $to ) = @_;

        return sub {
            my %results;
            for ( my $i = $from ; $i <= $to ; ++$i ) {
                $results{ $original_jobs[$i]->{name} } =
                  $original_jobs[$i]->{code}->();
            }
            return \%results;
        };
    };

    my ( $from, $to ) = ( 0, 0 );
    foreach my $id ( 1 .. $cpu ) {
        last if $from >= scalar @original_jobs;

        $to = $from + $jobs_per_cpu - 1;
        $to = scalar(@original_jobs) - 1 if $to >= scalar(@original_jobs);

        my $sub = $generate_sub->( $from, $to );

        push @new_jobs, { name => $id, code => $sub };
        $from = $to + 1;
    }

    $self->{jobs} = \@new_jobs;

    $self->run();

    # Unpack grouped results back into individual job results
    my %unpacked;
    for my $group_result ( values %{ $self->{result} } ) {
        next unless ref $group_result eq 'HASH';
        %unpacked = ( %unpacked, %$group_result );
    }
    $self->{result} = \%unpacked;

    return $self;
}


sub run {
    my ($self) = @_;

    return unless scalar @{ $self->{jobs} };
    $self->{failures} = [];

    my $pfm = $self->{pfork};
    for my $job ( @{ $self->{jobs} } ) {
        $pfm->start( $job->{name} ) and next;

        if ( my $timeout = $self->{timeout} ) {
            $SIG{ALRM} = sub {
                die "Job '$job->{name}' timed out after ${timeout}s\n";
            };
            alarm($timeout);
        }

        my $job_result;
        my $ok = eval {
            $job_result = $job->{code}->();
            1;
        };
        alarm(0) if $self->{timeout};
        if ($ok) {
            $pfm->finish( 0, { result => $job_result } );
        }
        else {
            $pfm->finish( 1, { error => "$@" } );
        }
    }

    # wait for all jobs
    $pfm->wait_all_children;

    if ( @{ $self->{failures} } ) {
        my @msgs;
        for my $f ( @{ $self->{failures} } ) {
            my $msg = "job $f->{id} (pid $f->{pid}): exit=$f->{exit}";
            $msg .= " signal=$f->{signal}" if $f->{signal};
            $msg .= " error=$f->{error}"   if $f->{error};
            push @msgs, $msg;
        }
        die "Job failures:\n  " . join( "\n  ", @msgs ) . "\n";
    }

    return $self->{result};
}


sub wait_for_all {
    my ($self) = @_;

    return $self unless $self->total_jobs;

    # Callbacks are fired in run_on_finish as each job completes
    $self->run();

    return $self;
}


sub results {
    my ($self) = @_;

    my @sorted =
      map  { $self->{result}{$_} }
      sort { int($a) <=> int($b) } keys %{ $self->{result} };
    return \@sorted;
}


sub result {
    my ( $self, $name ) = @_;

    croak "result() requires a job name" unless defined $name;

    my $position = $self->{named}{$name};
    croak "unknown job name '$name'" unless defined $position;

    return $self->{result}{$position};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parallel::Subs - Simple way to run subs in parallel and process their return value in perl

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Parallel::Subs;

    my $p = Parallel::Subs->new();
    #    or Parallel::Subs->new( max_process => N )
    #    or Parallel::Subs->new( max_process_per_cpu => P )
    #    or Parallel::Subs->new( max_memory => M )
    #    or Parallel::Subs->new( timeout => T );

    # add a first sub which will be launched by its own kid
    $p->add(  
        sub { # will be launched in parallel
            # any code that take time to execute can go there
            print "Hello from kid $$\n";
        }
    );
    # add a second sub
    $p->add(
        sub { print "Hello from kid $$\n" }
     );
    $p->add( \&do_something );

    # Trigger all the subs to run in parallel using a limited number of process
    $p->wait_for_all();

    print qq[This is done.\n];

=head2 Chaining the subs

You can also chain the 'add', or even the 'wait_for_all',
which can make your code easier to read.

    use Parallel::Subs;

    my $p = Parallel::Subs->new()
     ->add( sub{ print "Hello from kid $$\n"; sleep 5; } )
     ->add( sub{ print "Hello from kid $$\n"; sleep 4; } )
     ->add( sub{ print "Hello from kid $$\n"; sleep 3; } )
     ->add( sub{ print "Hello from kid $$\n"; sleep 2; } )
     ->add( sub{ print "Hello from kid $$\n"; sleep 1; } )
     ->add( sub{ print "Hello from kid $$\n" } )
     ->wait_for_all();
     # or ->wait_for_all_optimized(); # beta - group jobs and run one single fork per/cpu

    print qq[This is done.\n];

=head2 Run subs in parallel and use their return values

    use Parallel::Subs;

    my $sum;

    sub work_to_do {
        my ( $a, $b ) = @_;
        return sub {
            print "Running in parallel from process $$\n";
            # need some time to execute...
            # return 42;
            # return { value => 42 };
            # return [ 1..9 ];
            return $a * $b;
            }
    }

    sub read_result {
        my $result = shift;

        $sum += $result;
    }

    my $p = Parallel::Subs->new();
    $p->add(
        sub {
            my $time = int( rand(2) );
            sleep($time);
            return { number => 1, time => $time };
        },
        sub {
            # run from the main process once the kid process has finished its work
            #   to access return values from previous sub
            my $result = shift;
            $sum += $result->{number};

            return;
        }
        )->add( work_to_do( 1, 2 ), \&read_result )
        ->add( work_to_do( 3, 4 ),  \&read_result )
        ->add( work_to_do( 5, 6 ),  \&read_result )
        ->add( work_to_do( 7, 8 ),  \&read_result )
        ->add( work_to_do( 9, 10 ), \&read_result );

    $p->wait_for_all();

=head2 Named jobs

You can give jobs a name and retrieve their results by name instead of position.

    use Parallel::Subs;

    my $p = Parallel::Subs->new();
    $p->add( 'users',  sub { fetch_users()  } );
    $p->add( 'orders', sub { fetch_orders() } );
    $p->wait_for_all();

    my $users  = $p->result('users');
    my $orders = $p->result('orders');

Named and unnamed jobs can be mixed freely. C<results()> always returns
all results in insertion order regardless of naming.

=head1 DESCRIPTION

Parallel::Subs is a simple object interface used to launch tasks in parallel.
It uses L<Parallel::ForkManager> to run subroutines in child processes and
collect their return values.

You can also provide a second optional sub (callback) to process the result
returned by each child process from the main process.

=head1 NAME

Parallel::Subs - simple object interface to launch subs in parallel
and process their return values.

=head1 METHODS

=head2 new

Create a new Parallel::Subs object.

By default it will use the number of CPU cores as the maximum number of parallel jobs.
You can control this with the following options:

=over 4

=item * C<max_process> -set the maximum number of parallel processes directly

=item * C<max_process_per_cpu> -multiplied by the number of CPU cores

=item * C<max_memory> -in MB per job. Uses the minimum between the number of CPUs
and total available memory / max_memory (Linux only, requires
L<Sys::Statistics::Linux::MemStats>)

=item * C<timeout> -in seconds. If a child process takes longer than this,
it is killed via C<SIGALRM>. Applies to each fork individually (in optimized
mode, the timeout covers the grouped jobs within each fork).

=back

    my $p = Parallel::Subs->new();
    my $p = Parallel::Subs->new( max_process => 4 );
    my $p = Parallel::Subs->new( max_process_per_cpu => 2 );
    my $p = Parallel::Subs->new( max_memory => 512 );
    my $p = Parallel::Subs->new( timeout => 30 );

=head2 $p->add([$name], $code, [$callback])

Add a sub to be run in parallel. An optional name (string) can be provided
as the first argument to identify this job for later retrieval via C<result()>.

    $p->add( sub { 1 } );
    $p->add( sub { return { 1..6 } }, sub { my $result = shift; ... } );
    $p->add( 'fetch_users', sub { ... } );
    $p->add( 'compute', sub { heavy_calc() }, sub { process(shift) } );

=head2 $p->total_jobs

Returns the total number of jobs added so far.

=head2 $p->wait_for_all_optimized

Similar to C<wait_for_all> but reduces the number of forks by grouping
tasks together to be run by the same process.

B<Beta>: does not support callbacks. Callbacks will be cleared with a warning.

=head2 $p->run

Runs all added jobs in parallel and waits for them to complete.
Returns the raw results hashref (keyed by job name).
You typically don't need this method directly -use C<wait_for_all> instead.

=head2 $p->wait_for_all

Triggers all added jobs to run in parallel and waits for them to finish.
Callbacks (if any) are invoked as each job completes, not after all jobs
finish. This means callbacks fire in completion order, which may differ
from the order jobs were added.
Returns C<$self> for chaining.

=head2 $p->results

Returns an array reference of results, in the same order as jobs were added.

=head2 $p->result($name)

Returns the result for a named job. The name must have been provided
when the job was added via C<add()>.

    $p->add( 'fetch_users', sub { get_users() } );
    $p->wait_for_all();
    my $users = $p->result('fetch_users');

Croaks if the name is unknown.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
