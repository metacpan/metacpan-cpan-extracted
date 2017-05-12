# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Term-Chart/basic.t'

#########################

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {

    use_ok('Term::Chart')
        || die "failed to use Term::Chart\n";
}

#########################

my $x = "\x{2585}";

my $expect = join '',
    $x, (" ") x 24, "\n",
    ($x) x 3, (" ") x 22, "\n",
    ($x) x 5, (" ") x 20, "\n",
    ($x) x 8, (" ") x 17, "\n",
    ($x) x 10, (" ") x 15, "\n",
    ($x) x 13, (" ") x 12, "\n",
    ($x) x 15, (" ") x 10, "\n",
    ($x) x 17, (" ") x 8, "\n",
    ($x) x 20, (" ") x 5, "\n",
    ($x) x 22, (" ") x 3, "\n",
    ($x) x 25;

my $tc = Term::Chart->new( { width => 25 } );

for my $number ( 0 .. 10 )
{
    $tc->add_value( { value => $number } );
}

my $chart = "$tc";

utf8::decode($chart);

is( "\n$chart", "\n$expect", 'correct rendering of a basic chart' );

__END__
