#!/usr/bin/perl

use NCBIx::BigFetch;

# Parameters
my $params = { project_id => '1', 
               base_dir   => '/home/user/data' };

# Start project
my $project = NCBIx::BigFetch->new( $params );

# Find unavailable ids
my $ids = $project->unavailable_ids();

# Retrieve unavailable ids
foreach my $id ( @$ids ) { $project->get_sequence( $id ); }

exit;

