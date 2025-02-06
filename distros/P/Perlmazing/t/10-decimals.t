use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 6;
use Perlmazing qw(decimals);

is decimals 3.5, 0.5, 'Decimals returned correctly';
is decimals 3.6, 0.6, 'Decimals returned correctly';
is decimals 1.2345, 0.2345, 'Decimals returned correctly';
is decimals undef, 0, 'Decimals returned correctly';
is decimals '', 0, 'Decimals returned correctly';
eval {
  my $v = decimals 'string';
};
my $e = $@;
is $e =~ /^Use of non-numeric value in decimals\(\)/, 1, 'Decimals successfully failed with a string';
  

