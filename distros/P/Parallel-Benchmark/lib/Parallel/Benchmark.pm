package Parallel::Benchmark;
use strict;
use warnings;
our $VERSION = '0.10';

use Mouse;
use Log::Minimal;
use Time::HiRes qw/ tv_interval gettimeofday /;
use Parallel::ForkManager "1.12";
use Parallel::Scoreboard;
use File::Temp qw/ tempdir /;
use POSIX qw/ SIGUSR1 SIGUSR2 SIGTERM /;
use Try::Tiny;
use Scalar::Util qw/ blessed /;

has benchmark => (
    is      => "rw",
    isa     => "CodeRef",
    default => sub { sub { return 1 } },
);

has setup => (
    is      => "rw",
    isa     => "CodeRef",
    default => sub { sub { } },
);

has teardown => (
    is      => "rw",
    isa     => "CodeRef",
    default => sub { sub { } },
);

has time => (
    is      => "rw",
    isa     => "Int",
    default => 3,
);

has concurrency => (
    is      => "rw",
    isa     => "Int",
    default => 1,
);

has debug => (
    is      => "rw",
    isa     => "Bool",
    default => 0,
    trigger => sub {
        my ($self, $val) = @_;
        $ENV{LM_DEBUG} = $val;
    },
);

has stash => (
    is      => "rw",
    isa     => "HashRef",
    default => sub { +{} },
);

has scoreboard => (
    is => "rw",
    default => sub {
        my $dir = tempdir( CLEANUP => 1 );
        Parallel::Scoreboard->new( base_dir => $dir );
    },
);

sub run {
    my $self = shift;

    local $Log::Minimal::COLOR = 1
        if -t *STDERR;                ## no critic
    local $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace) = @_;
        warn "$time [$$] [$type] $message\n";
    };

    infof "starting benchmark: concurrency: %d, time: %d",
        $self->concurrency, $self->time;

    my $pm = Parallel::ForkManager->new( $self->concurrency );
    $pm->set_waitpid_blocking_sleep(0);  # true blocking calls enabled
    my $result = {
        score   => 0,
        elapsed => 0,
        stashes => {},
    };
    $pm->run_on_finish(
        sub {
            my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
            if (defined $data) {
                $result->{score}   += $data->[1];
                $result->{elapsed} += $data->[2];
                $result->{stashes}->{ $data->[0] } = $data->[3];
            }
        }
    );
    my $pids = {};
    local $SIG{INT} = $SIG{TERM} = sub {
        infof "terminating benchmark processes...";
        kill SIGTERM, keys %$pids;
        $pm->wait_all_children;
        exit;
    };

 CHILD:
    for my $n ( 1 .. $self->concurrency ) {
        my $pid = $pm->start;
        if ($pid) {
            # parent
            $pids->{$pid} = 1;
            next CHILD;
        }
        else {
            # child
            local $SIG{INT} = $SIG{TERM} = sub { exit };
            debugf "spwan child process[%d]", $n;
            my $r = $self->_run_on_child($n);
            $pm->finish(0, $r);
            exit;
        }
    }

    $self->_wait_for_finish_setup($pids);

    kill SIGUSR1, keys %$pids;
    my $start = [gettimeofday];
    try {
        my $teardown = sub {
            alarm 0;
            kill SIGUSR2, keys %$pids;
            $pm->wait_all_children;
            die;
        };
        local $SIG{INT}  = $teardown;
        local $SIG{ALRM} = $teardown;
        alarm $self->time;
        $pm->wait_all_children;
        alarm 0;
    };

    $result->{elapsed} = tv_interval($start);

    infof "done benchmark: score %s, elapsed %.3f sec = %.3f / sec",
        $result->{score},
        $result->{elapsed},
        $result->{score} / $result->{elapsed},
    ;
    $result;
}

sub _run_on_child {
    my $self = shift;
    my $n    = shift;

    my $r = [ $n, 0, 0, {} ];
    try {
        $self->scoreboard->update("setup_start");
        $self->setup->( $self, $n );
        $self->scoreboard->update("setup_done");
        $r = $self->_run_benchmark_on_child($n);
        $self->teardown->( $self, $n );
    }
    catch {
        my $e = $_;
        critf "benchmark process[%d] died: %s", $n, $e;
    };
    return $r;
}

sub _wait_for_finish_setup {
    my $self = shift;
    my $pids = shift;
    while (1) {
        sleep 1;
        debugf "waiting for all children finish setup()";
        my $stats = $self->scoreboard->read_all();
        my $done = 0;
        for my $pid (keys %$pids) {
            if (my $s = $stats->{$pid}) {
                $done++ if $s eq "setup_done";
            }
            elsif ( kill(0, $pid) == 1 ) {
                # maybe died...
                delete $pids->{$pid};
            }
        }
        last if $done == keys %$pids;
    }
}

sub _run_benchmark_on_child {
    my $self = shift;
    my $n    = shift;

    my ($wait, $run) = (1, 1);
    local $SIG{USR1} = sub { $wait = 0 };
    local $SIG{USR2} = sub { $run = 0  };
    local $SIG{INT}  = sub {};

    sleep 1 while $wait;

    debugf "starting benchmark process[%d]", $n;

    my $benchmark = $self->benchmark;
    my $score     = 0;
    my $start     = [gettimeofday];

    try {
        $score += $benchmark->( $self, $n ) while $run;
    }
    catch {
        my $e = $_;
        my $class = blessed $e;
        if ( $class && $class eq __PACKAGE__ . "::HaltedException" ) {
            infof "benchmark process[%d] halted: %s", $n, $$e;
        }
        else {
            die $e;
        }
    };

    my $elapsed = tv_interval($start);

    debugf "done benchmark process[%d]: score %s, elapsed %.3f sec.",
        $n, $score, $elapsed;

    return [ $n, $score, $elapsed, $self->stash ];
}

sub halt {
    my $self = shift;
    my $msg  = shift;
    die bless \$msg, __PACKAGE__ . "::HaltedException";
}

1;
__END__

=head1 NAME

Parallel::Benchmark - parallel benchmark module

=head1 SYNOPSIS

  use Parallel::Benchmark;
  sub fib {
      my $n = shift;
      return $n if $n == 0 or $n == 1;
      return fib( $n - 1 ) + fib( $n - 2 );
  }
  my $bm = Parallel::Benchmark->new(
      benchmark => sub {
          my ($self, $id) = @_;
          fib(10);  # code for benchmarking
          return 1; # score
      },
      concurrency => 3,
  );
  my $result = $bm->run;
  # output to STDERR
  #  2012-02-18T21:18:17 [INFO] starting benchmark: concurrency: 3, time: 3
  #  2012-02-18T21:18:21 [INFO] done benchmark: score 42018, elapsed 3.000 sec = 14005.655 / sec
  # $result hashref
  # {
  #   'elapsed' => '3.000074',
  #   'score'   => 42018,
  # }

=head1 DESCRIPTION

Parallel::Benchmark is parallel benchmark module.

=head1 METHODS

=over 4

=item B<new>(%args)

create Parallel::Benchmark instance.

  %args:
    benchmark:   CodeRef to benchmark.
    setup:       CodeRef run on child process before benchmark.
    teardown:    CodeRef run on child process after benchmark.
    time:        Int     benchmark running time. default=3
    concurrency: Int     num of child processes. default=1
    debug:       Bool    output debug log.       default=0

=item B<run>()

run benchmark. returns result hashref.

    {
      'stashes' => {
        '1' => { },   # $self->stash of child id==1
        '2' => { },
        ...
      },
      'score'   => 1886,        # sum of score
      'elapsed' => '3.0022655', # elapsed time (sec)
    };

=item B<stash>

HashRef to store some data while processing.

Child process's stash returns to result on parent process.

  $result = $bm->run;
  $result->{stashes}->{$id}; #= $self->stash on child $id

=item B<halt>()

Halt benchmark on child processes. it means normally exit.

  benchmark => sub {
      my ($self, $id) = @_;
      if (COND) {
         $self->halt("benchmark $id finished!");
      }
      ...
  },

=back

=head1 EXAMPLES

=head2 HTTP GET Benchmark

  use LWP::UserAgent;
  my $bm = Parallel::Benchmark->new(
      setup => sub {
          my ($self, $id) = @_;
          $self->stash->{ua} = LWP::UserAgent->new;
      },
      benchmark => sub {
          my ($self, $id) = @_;
          my $res = $self->stash->{ua}->get("http://127.0.0.1/");
          $self->stash->{code}->{ $res->code }++;
          return 1;
      },
      teardown => sub {
          my ($self, $id) = @_;
          delete $self->stash->{ua};
      },
      concurrency => 2,
  );
  my $result = $bm->run();
  # {
      'stashes' => {
        '1' => {
          'code' => {
            '200' => 932,
            '500' => 7
          }
        },
        '2' => {
          'code' => {
            '200' => 935,
            '500' => 12
          }
        }
      },
      'score' => 1886,
      'elapsed' => '3.0022655'
    }


=head1 AUTHOR

FUJIWARA Shunichiro E<lt>fujiwara@cpan.orgE<gt>

=head1 SEE ALSO

Parallel::ForkManager

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
