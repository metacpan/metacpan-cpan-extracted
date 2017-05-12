#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtTest4;

use Test::More tests => 23;

my $events = Qt::TestEventList();
$events->addKeyClick('a');
$events->addKeyClick(Qt::Key_Backspace());
$events->addDelay(200);

is(scalar @{$events}, 3, 'Qt::TestEventList::FETCHSIZE');
ok( exists $events->[0], 'Qt::TestEventList::EXISTS' );
ok( !exists $events->[4], 'Qt::TestEventList::EXISTS' );

my $event = $events->[0];
isa_ok($event, 'Qt::TestEvent', 'Qt::TestEventList::FETCH');

isa_ok( shift @{$events}, 'Qt::TestEvent', 'Qt::TestEventList::SHIFT' );
is(scalar @{$events}, 2, 'Qt::TestEventList::SHIFT');

push @{$events},
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyClicksEvent("Hello, World!", Qt::NoModifier(), -1);

is(scalar @{$events}, 4, 'Qt::TestEventList::PUSH');

@{$events} = ();

is(scalar @{$events}, 0, 'Qt::TestEventList::CLEAR');

push @{$events},
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyClicksEvent("Hello, World!", Qt::NoModifier(), -1);

$#{$events} = 3;
is(scalar @{$events}, 4, 'Qt::TestEventList::STORESIZE');

$event = pop @{$events};
is(scalar @{$events}, 3, 'Qt::TestEventList::POP');
isa_ok($event, 'Qt::TestEvent', 'Qt::TestEvent::POP');

ok( $events->[0] = $event, 'Qt::TestEvent::STORE' );
is(scalar @{$events}, 3, 'Qt::TestEventList::STORE');

unshift @{$events}, $event;
is(scalar @{$events}, 4, 'Qt::TestEventList::UNSHIFT');

my @gotEvents = splice @{$events};
is( scalar @gotEvents, 4, 'Qt::SignalSpy::SPLICE all' );
is( scalar @{$events}, 0, 'Qt::SignalSpy::SPLICE all' );

map { push @{$events}, Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1) } (0..5);
@gotEvents = splice @{$events}, 3;
is( scalar @gotEvents, 3, 'Qt::SignalSpy::SPLICE half' );
is( scalar @{$events}, 3, 'Qt::SignalSpy::SPLICE half' );

@{$events} = ();

map { push @{$events}, Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1) } (0..5);
@gotEvents = splice @{$events}, 10;
is( scalar @gotEvents, 0, 'Qt::SignalSpy::SPLICE off end' );

@gotEvents = splice @{$events}, 3, 1;
is( scalar @gotEvents, 1, 'Qt::SignalSpy::SPLICE half' );
is( scalar @{$events}, 5, 'Qt::SignalSpy::SPLICE half' );

@{$events} = ();
map { push @{$events}, Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1) } (0..5);
@gotEvents = splice @{$events}, 2, 3, 
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1),
    Qt::TestKeyEvent(Qt::Test::Click(), Qt::Key_A(), Qt::NoModifier(), -1);

is( scalar @gotEvents, 3, 'Qt::SignalSpy::SPLICE replace' );
is( scalar @{$events}, 9, 'Qt::SignalSpy::SPLICE replace' );

