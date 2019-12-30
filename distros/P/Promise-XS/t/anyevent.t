use strict;
use warnings;

use Test::More;
use Promise::XS;

eval { require AnyEvent; 1 } or plan skip_all => $@;

Promise::XS::use_event('AnyEvent');

my $deferred = Promise::XS::deferred();

$deferred->resolve(5);

my $value;

my $cv = AnyEvent->condvar();

$deferred->promise()->then( sub {
    $value = shift;
    $cv->();
} );

is( $value, undef, 'no immediate operation');

$cv->recv();

is( $value, 5, 'deferred operation runs');

done_testing();
