# NAME

Parallel::Benchmark - parallel benchmark module

# SYNOPSIS

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

# DESCRIPTION

Parallel::Benchmark is parallel benchmark module.

# METHODS

- __new__(%args)

    create Parallel::Benchmark instance.

        %args:
          benchmark:   CodeRef to benchmark.
          setup:       CodeRef run on child process before benchmark.
          teardown:    CodeRef run on child process after benchmark.
          time:        Int     benchmark running time. default=3
          concurrency: Int     num of child processes. default=1
          debug:       Bool    output debug log.       default=0

- __run__()

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

- __stash__

    HashRef to store some data while processing.

    Child process's stash returns to result on parent process.

        $result = $bm->run;
        $result->{stashes}->{$id}; #= $self->stash on child $id

- __halt__()

    Halt benchmark on child processes. it means normally exit.

        benchmark => sub {
            my ($self, $id) = @_;
            if (COND) {
               $self->halt("benchmark $id finished!");
            }
            ...
        },

# EXAMPLES

## HTTP GET Benchmark

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

# AUTHOR

FUJIWARA Shunichiro <fujiwara@cpan.org>

# SEE ALSO

Parallel::ForkManager

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
