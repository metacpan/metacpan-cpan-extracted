package OpenSearch::Remote;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;
use OpenSearch::Remote::Info;

sub info { shift; return ( OpenSearch::Remote::Info->new(@_) ); }

1;
