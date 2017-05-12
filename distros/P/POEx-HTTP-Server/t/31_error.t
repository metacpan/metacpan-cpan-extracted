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

plan tests => 5;

my $sock = IO::Socket::INET->new( LocalAddr => 0, Listen => 1, ReuseAddr => 1 );

my $uri = URI->new( "http://".$sock->sockhost.":".$sock->sockport );
DEBUG and 
    diag "Listen on $uri";

undef( $sock );

###############################################
# $DB::fork_TTY='/dev/pts/4';
my $child = gensym;
my $pid = pipe_from_fork( $child );
defined($pid) or die "Unable to fork: $!";
unless( $pid ) {    # child
    $poe_kernel->has_forked;
    # Give a slice to the server
    diag( "Sleep 1" ); sleep 1;
    my $UA = LWP::UserAgent->new;
    $UA->agent("$0/0.1 " . $UA->agent);

    my( $req, $resp );


    ##### Open a socket, send no request
    # This is a tad bogus; it will not provoke an on_error.
    # But it does make sure nothing explodes.
    $sock = IO::Socket::INET->new( PeerAddr=>'127.0.0.1', 
                                   PeerPort => $uri->port, 
                                   Blocking => 1 );
    $sock or die $@;
    undef( $sock );


    ##### Open a socket, send a bogus request
    $sock = IO::Socket::INET->new( PeerAddr=>'127.0.0.1', PeerPort => $uri->port, Blocking => 1 );
    $sock or die $@;
    $sock->printflush( "BOGUSREQUEST\n\n" );
    undef( $sock );

    ##### Open a socket, send a request without content
    $sock = IO::Socket::INET->new( PeerAddr=>'127.0.0.1', PeerPort => $uri->port, Blocking => 1 );
    $sock or die $@;
    $sock->printflush( <<HTTP );
GET / HTTP/1.1
Server: $0/0.1
Content-Encoding: fragged
Host: localhost

HTTP
    diag( "Sleep 1" ); sleep 1;

    # Make sure we get HTML back
    $resp = do { local $/; <$sock> };
    die "Wrong status\n$resp" unless $resp =~ m(411 Length);
    die "Not HTML\n$resp" unless $resp =~ m(<html>);

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
                            req error 
                            connect disconnect pre post ) ],
        ]
    );

POEx::HTTP::Server->spawn(
        inet => { BindPort => $uri->port },
        options => { debug => ::DEBUG, trace => 0 },
        headers => { Server => "$0/0.1" },
        handlers => [
                    ''              => 'poe:worker/req',
                    'on_error'      => 'poe:worker/error',
                ]
    );

$poe_kernel->run;
pass( "Exited" );

while(<$child>) {
    DEBUG and warn $_;
}
    

################################################################################
package Worker;

use strict;
use warnings;
use Test::More;
use Data::Dump qw( pp );
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
        fail( "No good requests!" );

        $resp->content( "hello world" );
    }
    $resp->content_type( 'text/plain' );
    $resp->respond;
    $resp->done;
}

sub error 
{
    my( $heap, $err ) = @_[ HEAP, ARG0 ];

    isa_ok( $err, 'POEx::HTTP::Server::Error' );
    if( $err->op ) {
        diag( $err->content );
    }
    else {
        ok( $err->is_error, " ... is an error" );
        # warn pp $err;
    }
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
    fail( "No requests" );
}

sub post
{
    my( $heap, $req, $resp ) = @_[ HEAP, ARG0, ARG1 ];
    fail( "No requests" );
}

