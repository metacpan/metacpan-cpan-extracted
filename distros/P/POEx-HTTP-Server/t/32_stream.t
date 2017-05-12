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
use URI::QueryParam;
use t::ForkPipe; 

eval "use LWP::UserAgent";
if( $@ ) {
    plan skip_all => "LWP::UserAgent isn't available";
    exit 0;
}

plan tests => 36;

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

    ##### Stream 20 blocks
    $uri->query_form( N=>10 );
    my $req = HTTP::Request->new( GET => $uri );
    my $resp = $UA->request( $req );
    my $c = $resp->content;
    die $c unless $c =~ m(1/10) and $c=~ m(10/10);

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
            Worker => [ qw( _start _stop shutdown pid
                            req stream ) ],
        ]
    );

POEx::HTTP::Server->spawn(
        inet => { BindPort => $uri->port },
        options => { debug => ::DEBUG, trace => 0 },
        headers => { Server => "$0/0.1" },
        handlers => [
                    ''               => 'poe:worker/req',
                    'stream_request' => 'poe:worker/stream'
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
        $resp->content_type( 'text/plain' );
        $resp->respond;
        $resp->done;
        return;
    }

    isa_ok( $req, 'POEx::HTTP::Server::Request' );
    isa_ok( $req->connection, 'POEx::HTTP::Server::Connection' );
    isa_ok( $resp, 'POEx::HTTP::Server::Response' );

    my $uri = $req->uri;
    isa_ok( $uri, 'URI' );
    my $N = $uri->query_param( 'N' );
    die "N must be set in ", pp $uri unless $N;
    ok( $N > 0, "$N must be greater then 0" );

    $resp->streaming( 1 );

    $heap->{N} = 0;
    $heap->{max} = $N;
    $resp->send;
}

#######################################
sub stream
{
    my( $heap, $req, $resp ) = @_[ HEAP, ARG0, ARG1 ];
    
    isa_ok( $req, 'POEx::HTTP::Server::Request' );
    isa_ok( $req->connection, 'POEx::HTTP::Server::Connection' );
    isa_ok( $resp, 'POEx::HTTP::Server::Response' );
    ::DEBUG and warn "N=$heap->{N} max=$heap->{max}";
    $heap->{N}++;
    $resp->send( "$heap->{N}/$heap->{max}\n" );
    if( $heap->{N} >= $heap->{max} ) {
        ::DEBUG and warn "DONE";
        $resp->done;
    }
}
