use Test::More tests => 2;
use Padre::Plugin::Swarm::Transport::Global;
use strict;
use warnings;

my $bailout = AnyEvent->condvar;
my $message = AnyEvent->condvar;
my $t = new Padre::Plugin::Swarm::Transport::Global
                host => 'swarm.perlide.org',
                port => 12000;
my $timeout = AnyEvent->timer( after=>10 , 
    cb => sub{ 
               $bailout->croak('timeout') ;
               $message->croak('timeout') ;
    }
);

$t->reg_cb( connect => sub {  ok('Connected'); $bailout->send; } );
$t->reg_cb( disconnect => sub { ok('Disconnected') ; $bailout->send } );
$t->enable;

$bailout->recv;
$t->reg_cb('recv', sub { ok(1,'Got message');$message->send } );

$t->send( {
    type => 'chat',
    from => '03_transport_global.t',
    body => 'Hello Global!',
} );
$message->recv;


