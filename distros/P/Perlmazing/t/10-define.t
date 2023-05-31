use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing;

my $scalar;
my @array = (undef, undef, undef);
is defined(define($scalar)), 1, 'scalar';
is undef, $scalar, 'scalar';
define @array;
is defined($array[0]), 1, 'list';
is defined($array[1]), 1, 'list';
is defined($array[2]), 1, 'list';
