package OpenSearch::Cluster;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;
#use OpenSearch::MooseTypes;
use OpenSearch::Cluster::Allocation;
use OpenSearch::Cluster::Health;
use OpenSearch::Cluster::Stats;
use OpenSearch::Cluster::Settings;

sub allocation { shift; return(OpenSearch::Cluster::Allocation->new(@_) ); }
sub health     { shift; return(OpenSearch::Cluster::Health->new(@_) );     }
sub stats      { shift; return(OpenSearch::Cluster::Stats->new(@_) );      }
sub settings   { shift; return(OpenSearch::Cluster::Settings->new(@_) );   }

1;
