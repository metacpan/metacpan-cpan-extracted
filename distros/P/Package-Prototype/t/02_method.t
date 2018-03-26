use strict;
use Test::More;

use_ok 'Package::Prototype';

sub __ANON__::foo { die "DIED" }

my $obj1 = Package::Prototype->bless({ foo => 10 });
ok $obj1->isa('__ANON__');
is ref $obj1, '__ANON__';
can_ok $obj1, 'foo';
is $obj1->foo, 10;

my $obj2 = Package::Prototype->bless({ bar => 10 }, 'CLASS');
ok $obj2->isa('CLASS');
is ref $obj2, 'CLASS';
can_ok $obj2, 'bar';
is $obj2->bar, 10;

my $obj3 = Package::Prototype->bless({ VERSION => $Package::Prototype::VERSION });
can_ok $obj3, 'VERSION';
is $obj3->VERSION, $Package::Prototype::VERSION;

# AUTOLOAD
my $obj4 = Package::Prototype->bless({ AUTOLOAD => sub { our $AUTOLOAD } });
is $obj4->moo, '__ANON__::moo';

# can this initialize stash?
my $obj5 = Package::Prototype->bless({});
ok !$obj5->can('foo');

my $obj6 = Package::Prototype->bless({ foo => 20 });
is $obj6->foo, 20;

# add some methods
$obj6->prototype(bar => sub { 300 }, baz => 40);
is $obj6->bar(), 300;
is $obj6->baz, 40;

# overload
my $obj7 = Package::Prototype->bless({ prototype => 20 });
is $obj7->prototype, 20;

done_testing;