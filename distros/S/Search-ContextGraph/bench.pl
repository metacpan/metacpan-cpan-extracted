#!/usr/bin/perl -w

use Benchmark;
use blib;
use Search::ContextGraph;
my $file = shift;
my $xs = shift or 0;

my $cg = Search::ContextGraph->new(dist_weight => 1, xs => $xs);
print "Loading from TDM\n";
$cg->load_from_tdm( $file );
print "Done\n";
my @t = $cg->dump_words();
#print join "\n", @t;

use Data::Dumper;
#$cg->search( $t[1] );
#print Dumper( $cg);
#exit;
$zip = 0;
timethis(5_000, 

	sub { my ( $docs, $words ) =  $cg->mixed_search( { terms => [111,109,23], docs => [33,21,12] }) ;
#		foreach my $k ( sort keys %{$words} ) {
#			 print $k, ' ', $words->{$k}, "\n";
#		}
#		print "\n\n-----------\n";
	});
