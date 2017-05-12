#!/usr/bin/perl 

use strict;
use warnings;

sub DEBUG () { 0 }

use Test::More;

use Data::Dump qw( pp );
use IO::Socket::INET;
use POE;
use POEx::HTTP::Server;
use Symbol;
use URI;
use t::ForkPipe; 

eval "use LWP::UserAgent";
if( $@ ) {
    plan skip_all => "LWP::UserAgent isn't available";
    exit 0;
}

plan tests => 26;

my $sock = IO::Socket::INET->new( LocalAddr => 0, Listen => 1, ReuseAddr => 1 );

my $uri = URI->new( "http://".$sock->sockhost.":".$sock->sockport );
DEBUG and 
    diag "Listen on $uri";

undef( $sock );

###############################################
my $child = gensym;
my $pid = pipe_from_fork( $child );
defined($pid) or die "Unable to fork: $!";
unless( $pid ) {    # child
    $poe_kernel->has_forked;
    diag( "Sleep 1" );
    sleep 1;
    my $UA = LWP::UserAgent->new;
    $UA->agent("$0/0.1 " . $UA->agent);

    ##### Tickle all/most of the special handlers
    my $req = HTTP::Request->new( GET => $uri );
    my $resp = $UA->request( $req );

    ##### Shut down the server
    $uri->path( '/shutdown' );
    $req = HTTP::Request->new( GET => $uri );
    $resp = $UA->request( $req );

    exit 0;
}

###############################################
# Parent

my $heap = { alias => 'worker', pid => $pid };
POE::Session->create(
        heap   => $heap,
        package_states => [
            Worker => [ qw( _start _stop shutdown  pid
                            req connect disconnect pre post ) ],
        ]
    );

POEx::HTTP::Server->spawn(
        inet => { BindPort => $uri->port },
        options => { debug => ::DEBUG, trace => 0 },
        headers => { Server => "$0/0.1" },
        handlers => [
                    ''              => 'poe:worker/req',
                    'on_connect'    => 'poe:worker/connect',
                    'on_disconnect' => 'poe:worker/disconnect',
                    'pre_request'   => 'poe:worker/pre',
                    'post_request'  => 'poe:worker/post',
                ]
    );

$poe_kernel->run;
pass( "Exited" );

while(<$child>) {
    DEBUG and warn $_;
}
    

is_deeply( $heap->{special}, [ 
            qw( on_connect pre_request post_request on_disconnect 
                on_connect pre_request post_request on_disconnect) ],
        "Everything, in order" );


################################################################################
package Worker;

use strict;
use warnings;
use Test::More;
use POE;

#######################################
sub _start
{
    my( $heap, $kernel ) = @_[HEAP, KERNEL];
    $kernel->alias_set( $heap->{alias} );
    $kernel->sig_child( $heap->{pid}, 'pid' );
    ::DEBUG and warn "$heap->{alias}: _start";
    # $kernel->sig( shutdown => 'shutdown' );
}

#######################################
sub _stop 
{
    my( $heap, $kernel ) = @_[HEAP, KERNEL];
    ::DEBUG and warn "$heap->{alias}: _stop";
}

#######################################
sub shutdown
{
    my( $heap, $kernel ) = @_[HEAP, KERNEL];
    $kernel->alias_remove( $heap->{alias} );
    ::DEBUG and warn "$heap->{alias}: shutdown";
}

#######################################
sub pid
{
    my( $heap, $kernel, $pid ) = @_[HEAP, KERNEL, ARG0];
    ::DEBUG and warn "$heap->{alias}: pid=$pid";
}

#######################################
sub req
{
    my( $heap, $req, $resp ) = @_[ HEAP, ARG0, ARG1 ];
    if( $req->uri->path =~ /shutdown/ ) {
        $poe_kernel->signal( $poe_kernel, 'shutdown' );
        $resp->content( 'OK' );
    }
    else {
        isa_ok( $req, 'POEx::HTTP::Server::Request' );
        isa_ok( $req->connection, 'POEx::HTTP::Server::Connection' );
        is( $req->connection->ID, $heap->{ID}, " ... same one" );
        isa_ok( $resp, 'POEx::HTTP::Server::Response' );

        $resp->content( "hello world" );
    }
    $resp->content_type( 'text/plain' );
    $resp->respond;
    $resp->done;
}

#######################################
sub connect
{
    my( $heap, $conn ) = @_[ HEAP, ARG0 ];
    push @{ $heap->{special} }, 'on_connect';
    isa_ok( $conn, 'POEx::HTTP::Server::Connection' );
    $heap->{ID} = $conn->ID;
}

sub disconnect
{
    my( $heap, $conn ) = @_[ HEAP, ARG0 ];
    push @{ $heap->{special} }, 'on_disconnect';
    isa_ok( $conn, 'POEx::HTTP::Server::Connection' );
    is( $conn->ID, $heap->{ID}, " ... same one" );
}

#######################################
sub pre
{
    my( $heap, $req ) = @_[ HEAP, ARG0 ];
    push @{ $heap->{special} }, 'pre_request';
    isa_ok( $req, 'POEx::HTTP::Server::Request' );
    isa_ok( $req->connection, 'POEx::HTTP::Server::Connection' );
    is( $req->connection->ID, $heap->{ID}, " ... same one" );
}

sub post
{
    my( $heap, $req, $resp ) = @_[ HEAP, ARG0, ARG1 ];
    push @{ $heap->{special} }, 'post_request';
    isa_ok( $req, 'POEx::HTTP::Server::Request' );
    isa_ok( $req->connection, 'POEx::HTTP::Server::Connection' );
    is( $req->connection->ID, $heap->{ID}, " ... same one" );
    isa_ok( $resp, 'POEx::HTTP::Server::Response' );
}

