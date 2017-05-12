package Salvation::AnyNotify::Plugin::Server;

use strict;
use warnings;

use base 'Salvation::AnyNotify::Plugin';

use AnyEvent ();
use Scalar::Util 'weaken';
use Salvation::TC ();
use Plack::Request ();
use Sub::Recursive 'recursive', '$REC';
use Twiggy::Server ();
use Salvation::DaemonDecl;
use Salvation::DaemonDecl::Backend ();
use Salvation::Method::Signatures;

our $VERSION = 0.01;

sub default_message_ttl { 60 }

sub default_queue_buffer_size { 1000 }

method bus_notify( Str{1,} channel, Str{1,} data ) {

    Salvation::DaemonDecl::Backend -> write_to(
        $self -> core() -> daemon() -> daemon_meta(),
        $self -> pid(),
        pack( 'N', length( $channel ) )
        . $channel
        . pack( 'N', length( $data ) )
        . $data
    );

    return;
}

method pid() {

    return $self -> { 'pid' };
}

method serve_request(
    Salvation::DaemonDecl::Worker worker, Plack::Request request,
    HashRef channels
) {

    my $channel = ( $channels -> { $request -> parameters() -> get( 'channel' ) // '' } // {} );
    my $now = time();
    my $ttl = $channel -> { 'ttl' };
    my $body = '';
    my @new_queue = ();
    my $response = $request -> new_response( 200 );

    while( defined( my $node = shift( @{ $channel -> { 'queue' } } ) ) ) {

        if( ( $node -> { 'time' } + $ttl ) > $now ) {

            push( @new_queue, $node );
        }

        $body .= pack( 'N', length( $node -> { 'data' } ) );
        $body .= $node -> { 'data' };
    }

    unshift( @{ $channel -> { 'queue' } }, @new_queue );

    $response -> content_type( 'text/plain' );
    $response -> body( $body );

    return $response -> finalize();
}

method start() {

    my $core = $self -> core();
    my $config = $core -> config();

    my $host = $config -> get( 'server.host' ),
    my $port = $config -> get( 'server.port' ),

    my $default_message_ttl = (
        $config -> get( 'server.default_message_ttl' )
        // $self -> default_message_ttl(),
    );

    my $default_queue_buffer_size = (
        $config -> get( 'server.default_queue_buffer_size' )
        // $self -> default_queue_buffer_size(),
    );

    Salvation::TC -> assert(
        [ $host, $port, $default_message_ttl, $default_queue_buffer_size ],
        'ArrayRef(
            Str{1,} host, Int port,
            Int default_message_ttl,
            Int default_queue_buffer_size
        )'
    );

    my $daemon_meta = $core -> daemon() -> daemon_meta();

    Salvation::DaemonDecl::Backend -> add_worker( $daemon_meta, {
        name 'http server',
        max_instances 1,
        log {
            warn @_;
        },
        ro,
        main {
            my ( $worker ) = @_;
            my $server = Twiggy::Server -> new( host => $host, port => $port );
            my %channels = ();

            $server -> register_service( sub {

                return $self -> serve_request(
                    $worker,
                    Plack::Request -> new( @_ ),
                    \%channels,
                );
            } );

            my @stack = ();
            my $cb; push( @stack, recursive {

                my $cv = AnyEvent -> condvar();

                # read channel length
                my $read_cv = $worker -> read_from_parent( 4, sub {

                    my ( $len ) = @_;
                    $len = unpack( 'N', $len );

                    # read channel value
                    my $read_cv = $worker -> read_from_parent( $len, sub {

                        my ( $channel ) = @_;
                        my $storage = $channels{ $channel } //= {};

                        $storage -> { 'ttl' } //= ( $config -> get( sprintf(
                            'server.channel.%s.ttl',
                            $channel,
                        ) ) // $default_message_ttl );

                        $storage -> { 'queue_buffer_size' } //= ( $config -> get( sprintf(
                            'server.channel.%s.queue_buffer_size',
                            $channel,
                        ) ) // $default_queue_buffer_size );

                        # read data length
                        my $read_cv = $worker -> read_from_parent( 4, sub {

                            my ( $len ) = @_;
                            $len = unpack( 'N', $len );

                            # read data
                            my $read_cv = $worker -> read_from_parent( $len, sub {

                                my ( $data ) = @_;

                                push( @{ $storage -> { 'queue' } }, {
                                    data => $data,
                                    time => time(),
                                } );

                                while( scalar( @{ $storage -> { 'queue' } } )
                                    > $storage -> { 'queue_buffer_size' } ) {

                                    shift( @{ $storage -> { 'queue' } } );
                                }
                            } );

                            $read_cv -> cb( sub { $cv -> send( scalar $read_cv -> recv() ) } );
                        } );

                        $read_cv -> cb( sub {

                            if( my $rv = $read_cv -> recv() ) {

                                $cv -> send( $rv );
                            }
                        } );
                    } );

                    $read_cv -> cb( sub {

                        if( my $rv = $read_cv -> recv() ) {

                            $cv -> send( $rv );
                        }
                    } );
                } );

                $read_cv -> cb( sub {

                    if( my $rv = $read_cv -> recv() ) {

                        $cv -> send( $rv );
                    }
                } );

                wait_cond( $cv );

                unless( scalar $cv -> recv() ) {

                    unless( defined $cb ) {

                        weaken( $cb = $REC );
                    }

                    push( @stack, $cb );
                }
            } );

            while( defined( my $code = shift( @stack ) ) ) {

                $code -> ();
            }

            undef @stack;
        },
    } );

    $self -> { 'pid' } = Salvation::DaemonDecl::Backend
        -> spawn_worker( $daemon_meta, 'http server' );
}

1;

__END__
