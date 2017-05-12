use strict;
use warnings;
use Test::More;

use_ok 'Sub::Rate';

my $rate = Sub::Rate->new( max_rate => 100 );
isa_ok $rate, 'Sub::Rate';

my ($r1, $r2, $r3);

$rate->add( 10 => sub { $r1++ } );
$rate->add( 20 => sub { $r2++ } );
$rate->add( default => sub { $r3++ });

my $func = $rate->generate;

for (1 .. 100000) {
    $func->();
}

ok 2.0*0.95 <= $r2 / $r1 && $r2 / $r1 <= 2.0*1.05, '$r2/$1 about 20/10 ok';
ok 7.0*0.95 <= $r3 / $r1 && $r3 / $r1 <= 7.0*1.05, '$r3/$1 about 70/10 ok';

$rate->clear;

is scalar @{ $rate->_func }, 0, 'func cleared ok';
ok !$rate->_default_func, 'default func cleared ok';

done_testing;


