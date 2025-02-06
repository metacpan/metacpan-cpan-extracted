use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Perlmazing qw(avg);

my @v = (5, 5, 10, 0);
is avg(@v), 5, 'Average value is correct';
is avg(2, 4, 4, 2), 3, 'Average value is correct';
is avg(1, 2), 1.5, 'Average value is correct';
is avg(undef, 'string', 3), 1, 'Average value is correct';