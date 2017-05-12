use strict;
use warnings;
use Test::More;
#use Data::Dumper;
use lib qw(lib ../lib);
use Net::GNUDBSearch::Cd;
plan(tests => 6);

my $config = {
	"id" => "cf11080f",
	"artist" => "The Prodigy",
	"album" => "-Their Law- The Singles 1990-2005",
	"genre" => "blues"
};
my $cd = Net::GNUDBSearch::Cd->new($config);
#1
isa_ok($cd, "Net::GNUDBSearch::Cd");

#2
is($cd->getArtist(), $config->{'artist'}, "getArtist()");

#3
is($cd->getAlbum(), $config->{'album'}, "getAlbum()");

#4
is($cd->getGenre(), $config->{'genre'}, "getGenre()");

#5
is($cd->getId(), $config->{'id'}, "getId()");

my @tracks = $cd->getTracks();
#6
is($#tracks, 14, "getTracks()");

#get the tracks again to check for caching
@tracks = $cd->getTracks();
