#!/usr/bin/env perl

package main;

use strict;
use warnings;
use autodie;

use IO::Socket::INET ();
use Types::Serialiser ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::WAMP::RawSocket::Client ();

my $SERIALIZATION = 'msgpack';

my $host_port = $ARGV[0] or die "Need [host:]port!";
substr($host_port, 0, 0) = 'localhost:' if -1 == index($host_port, ':');

my $inet = IO::Socket::INET->new(
    PeerAddr => $host_port,
    Blocking => 1,
);
die "[$!][$@]" if !$inet;

my $rs = Net::WAMP::RawSocket::Client->new(
    io => IO::Framed::ReadWrite->new( $inet ),
);

$rs->send_handshake( serialization => $SERIALIZATION );
$rs->verify_handshake();

#----------------------------------------------------------------------
use Carp::Always;

my $client = WAMP_Client->new(
    serialization => $SERIALIZATION,
    on_send => sub { $rs->send_message($_[0]) },
);

my $got_msg;

sub _receive {
    $got_msg = $rs->get_next_message();
    return $client->handle_message($got_msg->get_payload());
}

$client->send_HELLO( 'felipes_demo' ); #'myrealm',

use Data::Dumper;
print STDERR "RECEIVING …\n";
print Dumper(_receive());
print STDERR "RECEIVED …\n";

#----------------------------------------------------------------------

$client->send_REGISTER( {}, 'com.myapp.sum' );

#REGISTERED
my $reg_obj = _receive();
my $reg_id = $reg_obj->get('Registration');
print Dumper($reg_obj);

$client->send_CALL(
    { receive_progress => Types::Serialiser::true() },
    'com.myapp.sum',
    [2, 7, 3],
);

#INVOCATION
print Dumper(_receive());

#RESULT
while ( my $msg = _receive() ) {
    print Dumper($msg);
    last if !$msg->is_progress();
}

#----------------------------------------------------------------------

$client->send_GOODBYE();
print Dumper( _receive() );

#----------------------------------------------------------------------

package WAMP_Client;

use parent qw(
    Net::WAMP::Role::Caller
    Net::WAMP::Role::Callee
);

use IO::Framed::ReadWrite ();

sub on_INVOCATION {
    my ($self, $msg, $worker) = @_;

    my $reg_msg = $self->get_REGISTER($msg);

    my $procedure = $reg_msg->get('Procedure');

    my $proc_snake = $procedure;
    $proc_snake =~ tr<.><_>;

    my $method_cr = $self->can("RPC_$proc_snake");
    if (!$method_cr) {
        die "Unknown RPC procedure: “$procedure”";
    }

    if ($msg->caller_can_receive_progress()) {
print STDERR "caller can progress\n";
use Data::Dumper;
print STDERR Dumper $msg;
        $worker->yield_progress( {}, [ $method_cr->($self, $msg) ] );
    }

    my $yld = $worker->yield( {}, [ $method_cr->($self, $msg) ] );

    return;
}

sub RPC_com_myapp_sum {
    my ($self, $msg, $worker) = @_;

    my $sum = 0;
    $sum += $_ for @{ $msg->get('Arguments') };

    return $sum;
}

1;
