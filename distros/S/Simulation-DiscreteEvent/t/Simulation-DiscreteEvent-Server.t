use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use ok 'Simulation::DiscreteEvent::Server';

my $invalid_object = {};

{
    package Test::DE::Server;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server' }
 
    sub type { 'Test Server' }
    sub start : Event { return 'Started' }
    sub finish : Hey : Event(stop) { return $_[1] }
    sub empty : Event() {}
    sub junk : Junk(31) { 1 }
    no Moose;
    __PACKAGE__->meta->make_immutable;
}

my $server = Test::DE::Server->new( 
    name => 'Server1',
);

isa_ok $server, 'Test::DE::Server', 'server is created';
is $server->type, 'Test Server', 'server type is correct';
is $server->handle('start', undef), 'Started', 'start event is handled correctly';
is $server->handle('stop', 'Stopped'), 'Stopped', 'stop event is handled correctly';
lives_ok { $server->handle('empty') } 'Handler for empty was found';;
throws_ok { $server->handle('die', undef) } qr/unknown event/i, 'server has died on unknown event type';

