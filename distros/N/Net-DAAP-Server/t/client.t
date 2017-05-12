#!perl
use strict;
use warnings;
use Test::More tests => 4;
use lib 'lib', "$ENV{HOME}/lab/local/dapple/lib";
use POE;
use Net::DAAP::Server;
use Net::DAAP::Client 0.4;

my $name = "Net::DAAP::Server testsuite";
my $port = 23689;
my $pid = fork;
die "couldn't fork a server $!" unless defined $pid;
unless ($pid) {
    my $server = Net::DAAP::Server->new( path  => 't/share',
                                         port  => $port,
                                         name  => $name,
                                         debug => 0);
    diag( "starting kernel" );
    $poe_kernel->run;
    exit;
}

sleep 2; # give it time to warm up
diag( "Now testing" );

my $client = Net::DAAP::Client->new(
    SERVER_HOST => 'localhost',
    SERVER_PORT => $port,
    DEBUG       => 0,
   );

ok( $client->connect, "could connect and grab database" );
my $songs = $client->songs;
is( scalar keys %$songs, 3, "3 songs in the database" );


my @playlists = values %{ $client->playlists };
is( $playlists[0]{'dmap.itemname'}, $name, 'got main playlist');

my $playlist_tracks = $client->playlist( $playlists[0]{'dmap.itemid'} );
is( scalar @$playlist_tracks, 3, "3 tracks on main playlist" );


undef $client;
kill "TERM", $pid;
waitpid $pid, 0;

