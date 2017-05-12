#!perl
use strict;
use warnings;
use Test::More tests => 3;
use POE;
use Net::DPAP::Server;
use Net::DPAP::Client;

my $port = 23689;
my $pid = fork;
die "couldn't fork a server $!" unless defined $pid;
unless ($pid) {
    my $server = Net::DPAP::Server->new( path  => 't/share',
                                         port  => $port,
                                         debug => 0 );
    $poe_kernel->run;
    exit;
}

sleep 1; # give it time to warm up
diag( "Now testing" );

my $client = Net::DPAP::Client->new;
$client->hostname( 'localhost' );
$client->port( $port );

ok( my @albums = $client->connect, "could connect and grab albums" );
is( scalar @albums, 1, "advertising 1 album" );

is( scalar @{ $albums[0]->images }, 2, "2 images in that album");


undef $client;
kill "TERM", $pid;
waitpid $pid, 0;

