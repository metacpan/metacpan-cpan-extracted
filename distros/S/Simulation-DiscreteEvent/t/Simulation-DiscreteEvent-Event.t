use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use ok 'Simulation::DiscreteEvent::Event';

{
    package Test::DE::Server;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }
    sub test : Event(test) { ['test', @_ ] }
    sub test2 : Event(test2) { ['test2', @_ ] }
}
my $server = Test::DE::Server->new();

my $invalid_object = {};

my $event = Simulation::DiscreteEvent::Event->new( 
    time => 0, 
    server => $server,
    type => 'test',
);

isa_ok $event, 'Simulation::DiscreteEvent::Event', 'event is created';
dies_ok { $event->server($invalid_object) } "Server type check failed";
is $event->server, $server, "server value is correct";
throws_ok { $event->time("1:00pm") } qr/negative number/i, 'rejects invalid time';
throws_ok { $event->time(-4) } qr/negative number/i, 'rejects negative time';

is_deeply $event->handle, [ 'test', $server, undef ], 'handler is invoked correctly';

$event->type('test2');
$event->message("Hello!");
is $event->message, "Hello!", "message has been set";
is_deeply $event->handle, [ 'test2', $server, 'Hello!' ], 'handler is invoked correctly';


