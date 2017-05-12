use strict;
use warnings;
use Test::More;
#use Data::Dumper;
use lib qw(lib ../lib);
use Net::GNUDB::Cd;
plan(tests => 4);

my $config = {
	"id" => "cf11080f",
	"genre" => "blues"
};
my $cd = Net::GNUDB::Cd->new($config);
#1
isa_ok($cd, "Net::GNUDB::Cd");

#2
is($cd->getGenre(), $config->{'genre'}, "getGenre()");

#3
is($cd->getId(), $config->{'id'}, "getId()");

my @tracks = $cd->getTracks();
#print Dumper \@tracks;
#4
is($#tracks, 14, "getTracks()");

#get the tracks again to check for caching
@tracks = $cd->getTracks();
