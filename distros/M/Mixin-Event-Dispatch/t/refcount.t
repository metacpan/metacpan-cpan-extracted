use strict;
use warnings;
package Event::Raising::Class;
use parent qw(Mixin::Event::Dispatch);
sub new { bless {}, shift }
sub method { shift->invoke_event(method => @_) }
package main;
use Test::More tests => 10;
use Test::Refcount;

my $obj = Event::Raising::Class->new;
is_oneref($obj, 'instance has not picked up stray refs');
my $weak_ev;
$obj->subscribe_to_event(
	method => my $code = sub {
		my $ev = shift;
		isa_ok($ev, 'Mixin::Event::Dispatch::Event');
		Scalar::Util::weaken($weak_ev = $ev);
	},
);
is_oneref($obj, 'instance has still not picked up stray refs');
$obj->method;
is($weak_ev, undef, 'event goes away on completion');
is_oneref($obj, 'instance has still not picked up stray refs');
$obj->method;
is($weak_ev, undef, 'event goes away on completion');
is_oneref($obj, 'instance has still not picked up stray refs');

is($obj->unsubscribe_from_event(method => $code), $obj, 'unsubscribe from our event');
is_oneref($code, 'only have our ref leftover for the event handler');
done_testing;
