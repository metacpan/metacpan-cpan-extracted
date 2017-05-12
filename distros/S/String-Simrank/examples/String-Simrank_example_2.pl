#!/usr/bin/perl -w

# One can run this program directly from the directory above the 
# examples directory within the distribution directory with this command:
# perl examples/String-Simrank_example_2.pl

use strict;
use lib 'lib';
use String::Simrank;
use Storable;
use Data::Dumper;

my $sr = new String::Simrank( { data => 'test_data/mini_db.fasta'
                              });

my $numseqs = $sr->formatdb( { 
                    wordlen => 4,
		    pre_subst => 2,
		    minlen => 4,
                           } );


my $matches = $sr->match_oligos({ query => 'test_data/mini_db.fasta',
                    silent => 0,
		    pre_subst => 2,
                   });

print STDERR Dumper($matches);
foreach my $k (keys %{$matches} ) {
    print STDERR "matches for $k :\n";
    foreach my $hit ( @{ $matches->{$k} } ) {  
	# hits are ranked, best first
	print STDERR "hit id:" . $hit->[0] . " perc:" . $hit->[1] . "\n";
    }
}

1;
