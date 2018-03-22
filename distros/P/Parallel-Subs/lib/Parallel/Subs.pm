package Parallel::Subs;
$Parallel::Subs::VERSION = '0.002';
use strict;
use warnings;

use Parallel::ForkManager;
use Sys::Info;

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
    $self->{result} = {};
    $self->{pfork}->run_on_finish(
        sub {
            my ( $pid, $exit, $id, $exit_signal, $core_dump, $data ) = @_;
            die "Failed to process on one job, stop here !"
              if $exit || $exit_signal;
            $self->{result}->{$id} = $data->{result};
        }
    );
    $self->{jobs}      = [];
    $self->{callbacks} = [];

    return $self;
}

sub _pfork {
    my ( $self, %opts ) = @_;

    my $cpu;
    if ( defined $opts{max_process} ) {
        $cpu = $opts{max_process};
    }
    else {
        my $factor = $opts{max_process_per_cpu} || 1;
        eval { $cpu = Sys::Info->new()->device('CPU')->count() * $factor; };
    }
    if ( defined $opts{max_memory} ) {
        my $free_mem;
        eval {
            require Sys::Statistics::Linux::MemStats;
            $free_mem = Sys::Statistics::Linux::MemStats->new->get->{realfree};
        };
        my $max_mem = $opts{max_memory} * 1024;  # 1024 **2 = 1 GO => expr in Kb
        my $cpu_for_mem;
        if ($@) {

#warn "Cannot guess amount of available free memory need Sys::Statistics::Linux::MemStats\n";
            $cpu_for_mem = 2;
        }
        else {
            $cpu_for_mem = int( $free_mem / $max_mem );
        }

        # min
        $cpu = ( $cpu_for_mem < $cpu ) ? $cpu_for_mem : $cpu;
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
    my ( $self, $code, $test ) = @_;

    return unless $code && ref $code eq 'CODE';
    push(
        @{ $self->{jobs} },
        { name => ( scalar( @{ $self->{jobs} } ) + 1 ), code => $code }
    );
    push( @{ $self->{callbacks} }, $test );

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

            #print "subprocess from $from to $to\n";
            for ( my $i = $from ; $i <= $to ; ++$i ) {

                #print "running job $i\n";
                $original_jobs[$i]->{code}->();
            }
            return;
        };
    };

    my ( $from, $to ) = ( 0, 0 );
    foreach my $id ( 1 .. $cpu ) {
        $to = $from + $jobs_per_cpu - 1;
        $to = scalar(@original_jobs) - 1 if $to >= scalar(@original_jobs);

        #print "FROM $from - TO $to\n";
        my $sub = $generate_sub->( $from, $to );

        push @new_jobs, { name => $id, code => $sub };
        $from = $to + 1;
    }

    $self->{jobs} = \@new_jobs;

    return $self->wait_for_all();
}


sub run {
    my ($self) = @_;

    return unless scalar @{ $self->{jobs} };
    my $pfm = $self->{pfork};
    for my $job ( @{ $self->{jobs} } ) {
        $pfm->start( $job->{name} ) and next;
        my $job_result = $job->{code}();

        # can be used to stop on first error
        my $job_error = 0;
        $pfm->finish( $job_error, { result => $job_result } );
    }

    # wait for all jobs
    $pfm->wait_all_children;

    return $self->{result};
}


sub wait_for_all {
    my ($self) = @_;

    # run callbacks
    die "Cannot run callbacks" unless $self->run();

    return $self unless $self->total_jobs;
    my $c = 0;

    my $results = $self->results();

    foreach my $callback ( @{ $self->{callbacks} } ) {
        next unless $callback;
        die "cannot find result for #${c}" unless exists $results->[$c];
        my $res = $results->[ $c++ ];

        if ( ref $callback eq 'HASH' ) {

            # internal mechanism
            return
              unless defined $callback->{test} && defined $callback->{args};

            my @args = ( $res, @{ $callback->{args} } );
            my $t    = $callback->{test};
            my $str  = join( ', ', map { "\$args[$_]" } ( 0 .. $#args ) );
            eval "$t(" . $str . ")";
        }
        elsif ( ref $callback eq 'CODE' ) {

            # execute user function
            $callback->($res);
        }

    }

    return $self;
}


sub results {
    my ($self) = @_;

    my @sorted =
      map  { $self->{result}{$_} }
      sort { int($a) <=> int($b) } keys %{ $self->{result} };
    return \@sorted;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parallel::Subs - Simple way to run subs in parallel and process their return value in perl

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Parallel::Subs is a simple object interface used to launch test in parallel.
It uses Parallel::ForkManager to launch subs in parallel and get the results.

=head1 NAME
Parallel::Subs - simple object interface to launch subs in parallel
and process their return values.

=head1 Usage

You could also use the result returned by the function run in custom child process
from the main process by providing a second optional sub to process the results

=head2 The basics

    use Parallel::Subs;

    my $p = Parallel::Subs->new();
    #    or Parallel::Subs->new( max_process => N )
    #    or Parallel::Subs->new( max_process_per_cpu => P )
    #    or Parallel::Subs->new( max_memory => M );

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
     )
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
            note "Running in parallel from process $$";
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

=head1 METHODS

=head2 new

Create a new Parallel::Subs object.

By default it will use the number of cores you have as a maximum limit of parallelized job,
but you can control this value with two options :

- max_process : set the maximum process to this value

- max_process_per_cpu : set the maximum process per cpu, this value
will be multiplied by the number of cpu ( core ) avaiable on your server

- max_memory : in MB per job. Will use the minimum between #cpu and total memory available / max_memory

    my $p = Parallel::Subs->new()
        or Parallel::Subs->new( max_process => N )
        or Parallel::Subs->new( max_process_per_cpu => P )
        or Parallel::Subs->new( max_memory => M );

=head2 $p->add($code, [$callback])

You can add some sub to be run in parallel.

    $p->add( sub { 1 } );
    $p->add( sub { return { 1..6 } }, sub { my $result = shift; ... } );

=head2 $p->total_jobs

    return the total number of jobs

=head2 $p->wait_for_all_optimized

    similar to wait_for_all but the goal is to reduce the number of fork
    by grouping tasks together to be run by the same process

    For now this does not support callback. This is still in beta testing.

=head2 $p->run

will run and wait for all jobs added
you do not need to use this method except if you prefer to add jobs yourself and manipulate the results

=head2 $p->wait_for_all

    no process will be executed until you call this function
    which will then trigger parallel jobs and wait for all of them to finish    

=head2 $p->results

    get an array of results, in the same order of jobs

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
