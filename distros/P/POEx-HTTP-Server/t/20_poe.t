#!/usr/bin/perl

use strict;
use warnings;

sub DEBUG () { 0 }

use Symbol;
use Test::More;
use t::ForkPipe;

use Data::Dump qw( pp );
use IO::Socket::INET;
BEGIN { $POEx::HTTP::Server::Client::HAVE_SENDFILE = 0; }
use POEx::HTTP::Server;
use Symbol;
use URI;


use t::Server;


eval "use LWP::UserAgent";
if( $@ ) {
    plan skip_all => "LWP::UserAgent isn't available";
    exit 0;
}

eval "use HTTP::Request::Common qw(POST)";
if( $@ ) {
    plan skip_all => "HTTP::Request::Common isn't available";
    exit 0;
}

plan tests => 33;


my $sock = IO::Socket::INET->new( LocalAddr => 0, Listen => 1, ReuseAddr => 1 );

my $uri = URI->new( "http://".$sock->sockhost.":".$sock->sockport );
DEBUG and 
    diag "Listen on $uri";

undef( $sock );

# $DB::fork_TTY = '/dev/pts/4';

###############################################
my $child = gensym;
my $pid = pipe_from_fork( $child );
defined($pid) or die "Unable to fork: $!";
unless( $pid ) {
    $poe_kernel->has_forked;
    spawn( $uri->port );
    $poe_kernel->run;
    exit 0;
}

#######################################
# parent
diag "Sleep 1";
sleep 1;
my $UA = LWP::UserAgent->new;
$UA->agent("$0/0.1 " . $UA->agent);

##### plain response
my $req = HTTP::Request->new( GET => $uri );
my $resp = $UA->request( $req );

ok( $resp->is_success, "GET $uri" ) or die "Failed: ", pp $resp;
is( $resp->content_type, 'text/html', " ... text/html" );
my $c = $resp->content;
like( $c, qr(href="/static/something.txt), " ... one link" );
like( $c, qr(href="/dynamic/debug.txt), " ... two links" );

like( $resp->header( 'Server' ), qr($0), " ... our header" ) 
        or die pp $resp;
        

##### testing deffered response
$uri->path( '/dynamic/debug.txt' );
$req = HTTP::Request->new( GET => $uri );
$resp = $UA->request( $req );
ok( $resp->is_success, "GET $uri" ) or die "Failed: ", pp $resp;
$c = $resp->content;
like( $c, qr/REQ=bless/, " ... with request" );
like( $c, qr/POEx::HTTP::Server::Request/, " ... in the right class" );

like( $c, qr/POEx::HTTP::Server::Connection/, 
                " ... with a connection object" );
like( $c, qr/RESP=bless/, " ... with response" );
like( $c, qr/POEx::HTTP::Server::Response/, " ... in the right class" );

our( $PID, $REQ, $RESP );
eval $c;

is( $REQ->connection->remote_host, "127.0.0.1", " ... with remote IP" );
like( $REQ->connection->remote_port, qr/^\d+$/, " ... with remote port" );
is( $REQ->connection->local_host, "127.0.0.1", " ... with local IP" );
is( $REQ->connection->local_port, $uri->port, " ... with local port" );


##### testing sendfile
$uri->path( '/static/something.txt' );
$req = HTTP::Request->new( GET => $uri );
$resp = $UA->request( $req );
ok( $resp->is_success, "GET $uri" ) or die "Failed: ", pp $resp;
$c = $resp->content;
like( $c, qr/Windows or DOS/, " ... with the content" );
ok( $resp->header( 'Content-Length' ), " ... with Content-Length" );
ok( $resp->header( 'Last-Modified' ), " ... and Last-Modified" );


##### If-Modified-Since
$req = HTTP::Request->new( GET => $uri );
$req->header( 'If-Modified-Since' => $resp->header( 'Last-Modified' ) );
$resp = $UA->request( $req );
ok( !$resp->is_success, "If-Modified-Since: $uri" ) 
                or die "Failed: ", pp $resp;

is( $resp->code, 304, " ... not modified" );
ok( !$resp->header( 'Content-Length' ), " ... no Content-Length" );
is( $resp->content, '', " ... no content" );


##### HEAD
$req = HTTP::Request->new( HEAD => $uri );
$resp = $UA->request( $req );
ok( $resp->is_success, "HEAD $uri" ) 
                or die "Failed: ", pp $resp;

is( $resp->code, 200, " ... OK" );
ok( $resp->header( 'Content-Length' ), " ... with Content-Length" );
is( $resp->content, '', " ... no content" );


##### POST
$uri->path( '/dynamic/posted' );
$req = POST( $uri, [ honk=>'honk', bonk=>'bonk' ] );
$resp = $UA->request( $req );
ok( $resp->is_success, "POST $uri" ) 
                or die "Failed: ", pp $resp;

is( $resp->code, 200, " ... OK" );
ok( $resp->header( 'Content-Length' ), " ... with Content-Length" );
is( $resp->content, "bonk\nhonk\n", " ... no content" );


#####
$uri->path( '/shutdown' );
$req = HTTP::Request->new( GET => $uri );
$resp = $UA->request( $req );
ok( $resp->is_success, "GET $uri" ) or die "Failed: ", pp $resp;

while( <$child> ) {
    diag( $_ );
}


#####
END {
    if( $pid ) {
        kill 10, $pid;
        DEBUG and diag "PID=$pid";
        my $kid = waitpid( $pid, 0 );
        is( $?, 0, "Sane exit" );
    }
}
