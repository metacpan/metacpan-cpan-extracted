use strict;
use warnings;
use Test::More;
use Benchmark qw(cmpthese);

my $x = "datastring" x 8000;    # 8k string;
my $y = \$x;
my $c = 1000;

my $res = cmpthese(
    -1,
    {
        substr => sub {
            my @a = unpack 'C2Na28C', substr $$y, $c, 35;
            ();
        },
        unpack => sub {
            my @a = unpack 'x1000 C2Na28C', $$y;
            ();
        },
        unpack2 => sub {
            my @a = unpack "x$c C2Na28C", $$y;
            ();
        },
    }
);

ok $res;

done_testing;
