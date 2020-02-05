use strict;
use warnings;

use Test::More;
use Promise::XS;

eval { require Mojo::IOLoop; 1 } or plan skip_all => $@;

require Mojolicious;
diag "Mojolicious $Mojolicious::VERSION";

Promise::XS::use_event('Mojo::IOLoop');

my $deferred = Promise::XS::deferred();

$deferred->resolve(5);

my $value;

$deferred->promise()->then( sub {
    $value = shift;
    Mojo::IOLoop->stop();
} );

is( $value, undef, 'no immediate operation');

Mojo::IOLoop->start();

is( $value, 5, 'deferred operation runs');

done_testing();
