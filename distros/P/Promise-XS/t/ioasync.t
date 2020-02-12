use strict;
use warnings;

use Test::More;
use Promise::XS;

eval { require IO::Async::Loop; 1 } or plan skip_all => $@;

diag "IO::Async::Loop $IO::Async::Loop::VERSION";

my $loop = IO::Async::Loop->new();

Promise::XS::use_event('IO::Async' => $loop);

my $deferred = Promise::XS::deferred();

$deferred->resolve(5);

my $value;

$deferred->promise()->then( sub {
    $value = shift;
    $loop->stop();
} );

is( $value, undef, 'no immediate operation');

$loop->run();

is( $value, 5, 'deferred operation runs');

done_testing();
