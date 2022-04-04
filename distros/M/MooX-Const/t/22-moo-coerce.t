#!perl

use Test::Most;

use lib 't/lib';
use MooTest;

my $o;

lives_ok {
    $o = MooTest->new( bar => 2 );
} 'coercion';

is_deeply $o->bar, [2], 'coerced attribute';

done_testing;
