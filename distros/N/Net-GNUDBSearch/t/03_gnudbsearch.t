use strict;
use warnings;
use Test::More;
#use Data::Dumper;
use lib qw(lib ../lib);
use Net::GNUDBSearch;
plan(tests => 2);

my $search = Net::GNUDBSearch->new();
#1
isa_ok($search, "Net::GNUDBSearch");

my $results = $search->byArtist("The Prodigy");

{
	my $ok = 1;
	foreach my $result (@{$results}){
		#print Dumper $result;
		if(ref($result) ne "Net::GNUDBSearch::Cd"){
			$ok = 0;
			last;
		}
	}
	#2
	ok($ok, "All results are of the correct class");
}
