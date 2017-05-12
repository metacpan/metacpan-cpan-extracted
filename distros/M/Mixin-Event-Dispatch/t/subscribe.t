use strict;
use warnings;
package Event::Raising::Class;
use parent qw(Mixin::Event::Dispatch);
sub new { bless {}, shift }
sub method { shift->invoke_event(method => @_) }
package main;
use Test::More tests => 5;

my $obj = Event::Raising::Class->new;
$obj->subscribe_to_event(
	method => sub {
		my $ev = shift;
		isa_ok($ev, 'Mixin::Event::Dispatch::Event');
		can_ok($ev, qw(stop play defer name));
		is($ev->name, 'method', 'event name is correct');
		is($ev->stop, $ev, 'can request event stop');
		is($ev->play, $ev, 'can request event play');
	},
);
$obj->method;
done_testing;
