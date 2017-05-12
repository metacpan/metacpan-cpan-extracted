use strict;
use warnings;
use Test::More;

use Package::Anon;
use Scalar::Util qw(weaken);

my $stash = Package::Anon->new;
my $obj = $stash->bless({});

my $weak_stash = $stash;
weaken $weak_stash;

ok(!$obj->can('foo'));

$stash->add_method(foo => sub { 42 });
can_ok($obj, 'foo');
is($obj->foo, 42);

undef $stash;

ok($weak_stash, "something still holds strong reference to our stash");

can_ok($obj, 'foo');
is($obj->foo, 42);

undef $obj;

ok(! $weak_stash, "once the only instance of stash is gone, stash is GCed");

done_testing;
