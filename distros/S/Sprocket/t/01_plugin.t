#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More tests => 10;

BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
    use_ok 'Sprocket::Client';
    use_ok 'Sprocket::Server';
}

my %opts = (
    LogLevel => 1,
    TimeOut => 15,
);

my $srv = Sprocket::Server->spawn(
    %opts,
    Name => 'Test Server',
    ListenPort => 0,
    ListenAddress => '127.0.0.1',
    Plugins => [
        {
            plugin => Sprocket::Plugin::Test->new(),
        },
    ],
);

Sprocket::Client->spawn(
    %opts,
    Name => 'Test Client',
    ClientList => [
        '127.0.0.1:'.$srv->listen_port,
    ],
    Plugins => [
        {
            plugin => Sprocket::Plugin::Test->new(),
        },
    ],
);

$poe_kernel->run();


package Sprocket::Plugin::Test;

use Sprocket qw( Plugin );
use base 'Sprocket::Plugin';

use POE::Filter::Line;

use strict;
use warnings;

sub new {
    my $class = shift;
    $class->SUPER::new(
        name => 'Test',
        @_
    );
}

# ---------------------------------------------------------
# server

sub local_connected {
    my ( $self, $server, $con, $socket ) = @_;
    
    $self->take_connection( $con );
    # POE::Filter::Stackable object:
    $con->filter->push( POE::Filter::Line->new() );
    Test::More::pass('connected, sending test');
    
    $con->send( "Test!" );
}

sub local_receive {
    my ( $self, $server, $con, $data ) = @_;
    
    if ( $data =~ m/^Test!/i ) {
        $con->send( 'quit' );
        $con->postback( chain_quit => $con->callback( 'send_quit' ) )->();
        Test::More::pass('received test, sending quit');
    } elsif ( $data =~ m/^quit/i ) {
        $con->send( 'goodbye.' );
        Test::More::pass('received quit, closing connection');
        $con->close();
    }
}

sub chain_quit {
    my ( $self, $server, $con, $cb ) = @_;
    $cb->();
}

sub send_quit {
    my ( $self, $server, $con ) = @_;
    $con->send( 'quit' );
}

sub local_disconnected {
    my ( $self, $server, $con, $error ) = @_;
    Test::More::pass('local disconnected');
    $server->shutdown();
}

# ---------------------------------------------------------
# client

sub remote_connected {
    my ( $self, $client, $con, $socket ) = @_;

    $self->take_connection( $con );
    # POE::Filter::Stackable object:
    $con->filter->push( POE::Filter::Line->new() );
}

sub remote_receive {
    my ( $self, $client, $con, $data ) = @_;
    
    if ( $data =~ m/^Test!/i ) {
        Test::More::pass('received test, sending test');
        $con->postback( 'send_test' )->();
    } elsif ( $data =~ m/^quit/i ) {
        Test::More::pass('received quit, closing connection');
        $con->close();
    }
}

sub send_test{
    my ( $self, $client, $con ) = @_;
    $con->send( "Test!" );
}

sub remote_disconnected {
    my ( $self, $client, $con, $error ) = @_;
    Test::More::pass('remote disconnected');
    $client->shutdown();
}

sub remote_time_out {
    my ( $self, $client, $con, $error ) = @_;
    Test::More::fail("remote connect timeout");
    $client->shutdown();
}

sub remote_connect_error {
    my ( $self, $client, $con, $error ) = @_;
    Test::More::fail("remote connect failed");
    $client->shutdown();
}

1;
