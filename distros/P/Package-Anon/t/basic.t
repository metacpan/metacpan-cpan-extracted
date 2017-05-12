use strict;
use warnings;
use Test::More;

use Package::Anon;

sub __ANON__::foo { die 23 }

my $stash = Package::Anon->new;
my $obj = $stash->bless({});
ok !$obj->isa('__ANON__');
ok $obj->isa($stash);
is ref $obj, '__ANON__';

ok(!$obj->can('foo'));

$stash->add_method(foo => sub { 42 });
can_ok($obj, 'foo');
is($obj->foo, 42);

can_ok($obj, 'VERSION');
$stash->add_method(VERSION => sub { 13 });
can_ok($obj, 'VERSION');
is($obj->VERSION, 13);

$stash->add_method(AUTOLOAD => sub { our $AUTOLOAD });
is($obj->moo, '__ANON__::moo');

my $other_stash = Package::Anon->new;
my $other_obj = $other_stash->bless({});
ok !$other_obj->can('foo');

my $pkg = Package::Anon->blessed($obj);
isa_ok($pkg, 'Package::Anon');
is($pkg, $stash);
is(Package::Anon->blessed(42), undef);

done_testing;
