#!perl -T

use strict;
use warnings;

use Test::Most;
use Project::Euler::Lib::Utils qw/ :fibs /;


my @dies = (undef, 'a', ' 1', '1 ', '', 0, -1);
plan tests => (5 + scalar @dies);

my @fibs = qw/ 1  1  2  3  5  8  13  21  34  55 /;

my @gen_fibs;
my $fib_gen = fib_generator();
push @gen_fibs, $fib_gen->()  for  0..$#fibs;

cmp_deeply( \@fibs, \@gen_fibs, 'Fib generator produces the correct values' );


my $last_fib  = n_fibs( scalar @fibs );
my @n_fibs1   = n_fibs( scalar @fibs );
my @n_fibs2   = n_fibs( scalar @fibs );
my $fifth_fib = n_fibs( 5            );

cmp_deeply( \@fibs, \@n_fibs1, 'n_fibs1 produces the correct values' );
cmp_deeply( \@fibs, \@n_fibs2, 'n_fibs2 produces the correct values' );

is( $last_fib , $fibs[-1], 'n_fibs produces the last value in scalar context' );
is( $fifth_fib, 5        , 'n_fibs produces the correct value using the cache' );


for  my $die_val  (@dies) {
    dies_ok { n_fibs( $die_val ) } sprintf("The value '%s' should cause n_fibs to die", $die_val || '#UNDEFINED#');
}
