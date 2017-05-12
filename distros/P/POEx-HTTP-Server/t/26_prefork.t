#!/usr/bin/perl

use strict;
use warnings;

sub DEBUG () { 0 }

use Test::More;

use Data::Dump qw( pp );
use IO::Socket::INET;
use POEx::HTTP::Server;
use Symbol;
use URI;

use t::Server;
use t::ForkPipe; 


eval "use LWP::UserAgent";
if( $@ ) {
    plan skip_all => "LWP::UserAgent isn't available";
    exit 0;
}

eval "use POE::Component::Daemon 0.1200";
if( $@ ) {
    plan skip_all => "POE::Component::Daemon isn't available";
    exit 0;
}

plan tests => 11;


my $sock = IO::Socket::INET->new( LocalAddr => 0, Listen => 1, ReuseAddr => 1 );

my $uri = URI->new( "http://".$sock->sockhost.":".$sock->sockport );
DEBUG and 
    diag "Listen on $uri";

undef( $sock );

###############################################3
my $child = gensym;
my $pid = pipe_from_fork( $child );
defined($pid) or die "Unable to fork: $!";
unless( $pid ) {
    $poe_kernel->has_forked;
    spawn_prefork();
    spawn( $uri->port, 5, 1 );
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
ok( $c =~ qr/PID=(\d+)/, " ... with PID" );
my $first = $1;

$resp = $UA->request( $req );
ok( $resp->is_success, "GET $uri" ) or die "Failed: ", pp $resp;
$c = $resp->content;
ok( $c =~ qr/PID=(\d+)/, " ... with PID" );

my $second = $1;

isnt( $second, $first, "Different PIDs" );

kill 10, $pid if $pid;
while( <$child> ) { diag( $_ ); }


#####
END {
    if( $pid ) {
        kill 10, $pid;
        DEBUG and diag "PID=$pid";
        my $kid = waitpid( $pid, 0 );
        is( $?, 0, "Sane exit" );
    }
}
