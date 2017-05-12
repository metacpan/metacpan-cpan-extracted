#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More tests => 4;

BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
    use_ok 'Sprocket::Server';
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

my $srv2 = Sprocket::Server->spawn(
    %opts,
    Name => 'Test Server 2',
    ListenPort => $srv->listen_port,
    ListenAddress => '127.0.0.1',
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

# ---------------------------------------------------------
# server

sub local_error {
    my ( $self, $server, $operation, $errnum, $errstr ) = @_;
    Test::More::pass("local bind error: intentional");
    $poe_kernel->post( 'test' => 'shutdown' );
}

1;
