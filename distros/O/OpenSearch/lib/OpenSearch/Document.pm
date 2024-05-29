package OpenSearch::Document;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Document::Index;
use OpenSearch::Document::Bulk;

sub index( $self, @params ) {
  return ( OpenSearch::Document::Index->new(@params)->execute );
}

sub bulk( $self, @params ) {
  return ( OpenSearch::Document::Bulk->new(@params)->execute );
}

1;
