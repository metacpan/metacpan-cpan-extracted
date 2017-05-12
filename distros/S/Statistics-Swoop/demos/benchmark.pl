use strict;
use warnings;
use Benchmarks sub {
    use Statistics::Swoop;
    use Statistics::Lite qw//;

    my @LIST = (1..10000);

    my $swoop = sub {
        my $ss = Statistics::Swoop->new(\@LIST);
        return(
            $ss->sum,
            $ss->max,
            $ss->min,
            $ss->range,
            $ss->avg,
        );
    };

    my $lite = sub {
        return(
            Statistics::Lite::sum(@LIST),
            Statistics::Lite::max(@LIST),
            Statistics::Lite::min(@LIST),
            Statistics::Lite::range(@LIST),
            Statistics::Lite::mean(@LIST),
        );
    };

    return {
        'Swoop' => $swoop,
        'Lite'  => $lite,
    };
};

=pod

    Benchmark: running Lite, Swoop for at least 1 CPU seconds...
          Lite: 1.08572 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 111.11/s (n=120)
         Swoop: 1.06509 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 316.04/s (n=335)
           Rate  Lite Swoop
    Lite  111/s    --  -65%
    Swoop 316/s  184%    --

=cut
