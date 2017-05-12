use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);
use Object::Tap;

my $tapped;

sub Foo::bar { $tapped = join(' ', @_) }

is(Foo->$_tap(sub { $_[0]->bar($_[1]) }, 'one'), 'Foo', 'invocant returned');

is($tapped, 'Foo one', 'subref tap');

is(Foo->$_tap(bar => 'two'), 'Foo', 'invocant returned');

is($tapped, 'Foo two', 'method name tap');
