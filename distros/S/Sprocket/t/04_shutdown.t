#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More tests => 8;

BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
    use_ok 'Sprocket::Client';
    use_ok 'Sprocket::Server';
    use_ok 'POE::Filter::Line';
}

my %opts = (
    LogLevel => 0,
    TimeOut => 0,
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

my $cli = Sprocket::Client->spawn(
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

POE::Session->create( inline_states => {
    _start => sub {
        $poe_kernel->delay( shutdown => 5 => 1 );
        $poe_kernel->alias_set( 'test' );
    },
    shutdown => sub {
        my $failed = $_[ ARG0 ];
        Test::More::fail("test failed")
            if ( $failed );
        $poe_kernel->alias_remove( 'test' );
        $poe_kernel->alarm_remove_all();
    },
    _stop => sub {
        $sprocket->shutdown_all();
    }
} );

$poe_kernel->run();


package Sprocket::Plugin::Test;

use Sprocket qw( Plugin );
use base 'Sprocket::Plugin';
use POE;

use strict;
use warnings;

sub new {
    my $class = shift;
    $class->SUPER::new(
        name => 'Test Plugin',
        @_
    );
}

# server listens
# client connects, and sends shutdown_all
# server recevies shutdown, sends bye, and closes connection
# client gets a closed connection and leaves

# ---------------------------------------------------------
# server
    
sub local_connected {
    my ( $self, $server, $con ) = @_;
    $self->take_connection( $con );
    $con->filter->push( POE::Filter::Line->new() );
}

sub local_shutdown {
    my ( $self, $server, $con ) = @_;
    Test::More::pass("received soft shutdown message, closing");
    $con->send('shutting down');
    $con->close();
}

sub remote_connected {
    my ( $self, $client, $con ) = @_;
    $self->take_connection( $con );
    $con->filter->push( POE::Filter::Line->new() );
    Test::More::pass("client connected to server, starting soft shutdown");
    $sprocket->shutdown_all( 'soft' );
}

sub remote_receive {
    my ( $self, $client, $con ) = @_;
    Test::More::pass("received soft shutdown");
}

sub remote_disconnected {
    my ( $self, $client, $con ) = @_;
    Test::More::pass("connection closed, done");
    $con->close();
    $poe_kernel->post( test => 'shutdown' );
}


1;
