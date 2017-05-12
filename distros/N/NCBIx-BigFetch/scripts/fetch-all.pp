#!/usr/bin/perl

use NCBIx::BigFetch;

# Parameters
my $params = { project_id  => '1', 
               base_dir    => '/home/user/data', 
	       db          => 'protein',
	       query       => 'apoptosis',
	       return_type => 'fasta',
               return_max  => '500' };

# Start project
my $project = NCBIx::BigFetch->new( $params );

# Pat yourself on the back
print " AUTHORS: " . $project->authors() . "\n";

# Attempt all batches of sequences
while ( $project->results_waiting() ) { $project->get_next_batch(); }

# Get missing batches 
while ( $project->missing_batches() ) { $project->get_missing_batch(); }

# Find unavailable ids
my $ids = $project->unavailable_ids();

# Retrieve unavailable ids
foreach my $id ( @$ids ) { $project->get_sequence( $id ); }

exit;

