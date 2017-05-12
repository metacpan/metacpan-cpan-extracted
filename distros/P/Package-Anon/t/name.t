use strict;
use warnings;
use Test::More;

use Package::Anon;

sub Foo::foo { die 23 }

my $stash = Package::Anon->new('Foo');
my $obj = $stash->bless({});
ok !$obj->isa('Foo');
ok $obj->isa($stash);
is ref $obj, 'Foo';

ok(!$obj->can('foo'));

$stash->add_method(foo => sub { 42 });
can_ok($obj, 'foo');
is($obj->foo, 42);

can_ok($obj, 'VERSION');
$stash->add_method(VERSION => sub { 13 });
can_ok($obj, 'VERSION');
is($obj->VERSION, 13);

$stash->add_method(AUTOLOAD => sub { our $AUTOLOAD });
is($obj->moo, 'Foo::moo');

my $other_stash = Package::Anon->new;
my $other_obj = $other_stash->bless({});
ok !$other_obj->can('foo');

done_testing;
