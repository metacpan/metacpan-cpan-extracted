#!/usr/local/bin/perl -w
$|++;
use strict;
use Test::More;
use IO::File;
use lib qw( ../lib );
use vars qw( $port @pids );
BEGIN { plan tests => 15 }
$port = 20444;

# arguments for use in tests
my %args = (
    Pager => 5555555555,
    Message => "The sky is falling!",
    Alert   => 1,
    Hold    => time + 3
);

use_ok( 'Net::SNPP::Server' );
use_ok( 'Net::SNPP' );

ok( my $server = Net::SNPP::Server->new( Port => $port ), "created a server" );

# disable logging from server (comment next line out to turn it on)
$server->callback( 'write_log', sub { } );

my( $rp, $pid ) = $server->forked_server(1);
push( @pids, $pid );
diag( "test server up and running on $port" );

diag( "attempting to connect to server using Net::SNPP" );
ok( my $snppclient = Net::SNPP->new( 'localhost', Port => $port ),
    "connected to server using Net::SNPP client" );

# uncomment the following to turn on Net::SNPP debugging
# $snppclient->debug( 10 );

# test $snppclient->ping();
ok( $snppclient->ping( $args{Pager} ), "client->ping()" );

ok( $snppclient->send( %args ), "client->send()" );
ok( $snppclient->reset(), "client->reset()" );

diag "testing 2way capabilities (level 3)";
ok( $snppclient->two_way(), "client->two_way()" );
ok( $snppclient->pager_id( $args{Pager} ), "client->pager_id( $args{Pager} )" );
ok( $snppclient->data(<<EODATA), "client->data(<<EODATA);" );
This is a test
data message
with newlines in it
EODATA
ok( $snppclient->message_response( 1, "Test1" ), "client->message_response(1, 'Test1')" );
ok( $snppclient->message_response( 2, "Test2" ), "client->message_response(2, 'Test2')" );
ok( $snppclient->message_response( 3, "Test3" ), "client->message_response(3, 'Test3')" );
ok( $snppclient->message_response( 4, "Test4" ), "client->message_response(4, 'Test4')" );

ok( $snppclient->quit(), "client->quit()" );

foreach my $pid ( @pids ) {
    kill( 2, $pid );
    waitpid( $pid, 1 );
}

exit 0;


