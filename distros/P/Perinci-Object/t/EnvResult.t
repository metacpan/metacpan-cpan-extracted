#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Object;

my $envres = envres [200, "OK", [1, 2, 3]];

is_deeply($envres->as_struct, [200, "OK", [1, 2, 3]], "as_struct 1");

is($envres->status, 200, "status");
is($envres->status(250), 200, "status (set) 1");
is($envres->status, 250, "status (set) 2");

ok($envres->is_success, "is_success 1");

is($envres->message, "OK", "message");
is($envres->message("Not found"), "OK", "message (set) 1");
is($envres->message, "Not found", "message (set) 2");

is($envres->status(404), 250, "status (set) 3");
ok(!$envres->is_success, "is_success 2");

is_deeply($envres->payload, [1,2,3], "payload");
is_deeply($envres->payload([4,5,6]), [1,2,3], "payload (set) 1");
is_deeply($envres->payload, [4,5,6], "payload (set) 2");

ok(!$envres->meta, "extra");
ok(!$envres->meta({errno=>-100}), "meta (set) 1");
is_deeply($envres->meta, {errno=>-100}, "meta (set) 2");

is_deeply($envres->as_struct,
          [404, "Not found", [4, 5, 6], {errno=>-100}], "as_struct 2");

done_testing();
