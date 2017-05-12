#
#
# vim: syntax=perl

use warnings;
use strict;

use Test::More 'no_plan';

BEGIN {
    use_ok 'POE';
    use_ok 'Sprocket';
    use_ok 'Sprocket::Server';
    use_ok 'Sprocket::Client';
}


POE::Session->create( inline_states => {
    _start => sub {
        $sprocket->attach_hook( [qw(
            sprocket.remote.connection.accept
            sprocket.remote.connection.receive
            sprocket.remote.wheel.error
            sprocket.local.connection.accept
            sprocket.local.connection.receive
            sprocket.local.wheel.error
            sprocket.shutdown
        )], $sprocket->callback( $_[SESSION] => 'handle_callback' ) );
        
        $poe_kernel->delay( shutdown => 10 => 1 );
        $poe_kernel->alias_set( 'test' );

        my %opts = (
            LogLevel => 1,
            TimeOut => 0,
        );
        
        my @template = (
            'test1',
            'test2',
            'test3',
            'test4',
        );
        
        my $srv = Sprocket::Server->spawn(
            %opts,
            Name => 'Test Server',
            ListenPort => 0,
            ListenAddress => '127.0.0.1',
            Plugins => [
                {
                    plugin => Sprocket::Plugin::Test->new(
                        template => [ @template ],
                    ),
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
                    plugin => Sprocket::Plugin::Test->new(
                        template => [ @template ],
                    ),
                },
            ],
        );
    },
    handle_callback => sub {
        my $event = $_[ARG0];
        Test::More::pass("callback ".$event->hook);
        $poe_kernel->yield( 'shutdown' )
            if ( $event->hook eq 'sprocket.shutdown' );
    },
    shutdown => sub {
        my $failed = $_[ ARG0 ];
        Test::More::fail("test failed")
            if ( $failed );
        $poe_kernel->alias_remove( 'test' );
        $poe_kernel->alarm_remove_all();
        delete $_[HEAP]->{cb};
        return;
    },
} );

$poe_kernel->run();


package Sprocket::Plugin::Test;

use Sprocket qw( Plugin );
use base 'Sprocket::Plugin';

use POE::Filter::Line;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
        name => 'Test',
        @_
    );

    my $tpl = $self->{template};
    $self->{template} = [ (<$tpl>) ]
        if ( $tpl && ref $tpl eq 'GLOB' );
    
    die "must specify template for tests"
        unless( $self->{template} );

    return $self;
}

sub next_item {
    my $self = shift;
    
    shift @{$self->{template}};
}

# ---------------------------------------------------------
# server

sub local_connected {
    my ( $self, $server, $con, $socket ) = @_;
    
    $self->take_connection( $con );
    # POE::Filter::Stackable object:
    $con->filter->push( POE::Filter::Line->new() );
    
    $con->filter->shift(); # POE::Filter::Stream

    Test::More::pass("l - connected, starting test");
    
    my $n = $self->next_item();
    if ( $n ) {
        Test::More::pass("l - sent '$n'");
        $con->send( $n );
    } else {
        Test::More::fail("l - no test data in the template");
        $server->shutdown();
    }
}

sub local_receive {
    my ( $self, $server, $con, $data ) = @_;
    
    my $n = $self->next_item();

    unless ( $n ) {
        Test::More::fail("l - data received '$data' but no matching item");
        kill(INT => $$);
        return;
    }

    if ( $data =~ m/^$n$/ ) {
        Test::More::pass("l - received valid result for '$n'");
        my $send = $self->next_item();
        if ( $send ) {
            Test::More::pass("l - sending '$send'");
            $con->send( $send );
        } else {
            Test::More::pass("l - last item in template, end of test");
            $con->close();
        }
    } else {
        Test::More::fail("l - received INVALID result for '$n' : '$data'");
        $server->shutdown();
    }
}

sub local_disconnected {
    my ( $self, $server, $con, $error, $operation, $errnum, $errstr ) = @_;
    if ( $error && $errnum != 0 ) {
        Test::More::fail("l - disconnected error op: $operation num: $errnum err: $errstr");
    } else {
        Test::More::pass("l - disconnected");
    }
    $server->shutdown();
}

# ---------------------------------------------------------
# client

sub remote_connected {
    my ( $self, $client, $con, $socket ) = @_;

    $self->take_connection( $con );

    # POE::Filter::Stackable object:
    $con->filter->push( POE::Filter::Line->new() );
    
    $con->filter->shift(); # POE::Filter::Stream

    return;
}

sub remote_receive {
    my ( $self, $client, $con, $data ) = @_;
    
    my $n = $self->next_item();

    unless ( $n ) {
        Test::More::fail("r - data received '$data' but no matching item");
        kill(INT => $$);
        return;
    }

    if ( $data =~ m/^$n$/ ) {
        Test::More::pass("r - received valid result for '$n'");
        my $send = $self->next_item();
        if ( $send ) {
            Test::More::pass("r - sending '$send'");
            $con->send( $send );
        } else {
            Test::More::pass("r - last item in template, end of test");
            $con->close();
        }
    } else {
        Test::More::fail("r - received INVALID result for '$n' : '$data'");
        $client->shutdown();
    }
}

sub remote_disconnected {
    my ( $self, $client, $con, $error, $operation, $errnum, $errstr ) = @_;
    if ( $error && $errnum != 0 ) {
        Test::More::fail("r - disconnected error op: $operation num: $errnum err: $errstr");
    } else {
        Test::More::pass("r - disconnected");
    }
    $client->shutdown();
}

sub remote_connect_timeout {
    my ( $self, $client, $con, $time ) = @_;
    Test::More::fail("r - connect timeout");
    $client->shutdown();
}

sub remote_connect_error {
    my ( $self, $client, $con, $operation, $errnum, $errstr ) = @_;
    Test::More::fail("r - connect error op: $operation num: $errnum err: $errstr");
    $client->shutdown();
}

1;
