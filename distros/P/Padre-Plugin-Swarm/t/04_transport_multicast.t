use Test::More tests => 2;
use Padre::Plugin::Swarm::Transport::Local;

my $bailout = AnyEvent->condvar;
my $message = AnyEvent->condvar;

my $t = new Padre::Plugin::Swarm::Transport::Local
                host => 'swarm.perlide.org',
                port => 12000;
my $timeout = AnyEvent->timer( after=>10 , cb=>sub{ $bailout->croak('timeout') } );

$t->reg_cb( connect => sub {
        ok(1,'Connected'); 
        $bailout->send; 
} );
$t->reg_cb( disconnect => sub { ok(1,'Disconnected') ; $bailout->send } );

$t->enable;
$bailout->recv;

$t->reg_cb( recv => sub { ok(1,'Got message'); $message->send } ) ;

$t->send( { 
    type => 'chat',
    from => '04_transport_multicast.t',
    body => 'Hello Multicast!',
} );

$message->recv;
