#!/usr/bin/perl -w

# One can run this program directly from the directory above the 
# examples directory within the distribution directory with this command:
# perl examples/String-Simrank_example_1.pl

use strict;
use lib 'lib';
use String::Simrank;
use Storable;
use Data::Dumper;

my $sr = new String::Simrank( { data => 'test_data/db.fasta'
                              });

my $numseqs = $sr->formatdb( { 
                    wordlen => 7,
		    valid_chars => 'ACGT'
                           } );


my $matches = $sr->match_oligos({ query => 'test_data/query.fasta',
                    silent => 0,
		    valid_chars => 'ACGT'
                   });


print STDERR Dumper($matches);
foreach my $k (keys %{$matches} ) {
    print STDERR "matches for $k :\n";
    foreach my $hit ( @{ $matches->{$k} } ) {
	print STDERR "hit id:" . $hit->[0] . " perc:" . $hit->[1] . "\n";
    }
}

1;
