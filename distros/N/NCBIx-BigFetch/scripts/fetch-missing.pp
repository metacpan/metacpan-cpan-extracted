#!/usr/bin/perl

use NCBIx::BigFetch;

# Parameters
my $params = { project_id => '1', 
               base_dir   => '/home/user/data' };

# Start project
my $project = NCBIx::BigFetch->new( $params );

# Get missing batches 
while ( $project->missing_batches() ) { $project->get_missing_batch(); }

exit;

