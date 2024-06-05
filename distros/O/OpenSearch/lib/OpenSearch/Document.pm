package OpenSearch::Document;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Document::Index;
use OpenSearch::Document::Bulk;
use OpenSearch::Document::Get;

sub index( $self, @params ) {
  return ( OpenSearch::Document::Index->new(@params)->execute );
}

sub bulk( $self, @params ) {
  return ( OpenSearch::Document::Bulk->new(@params)->execute );
}

sub get( $self, @params ) {
  return ( OpenSearch::Document::Get->new(@params)->execute );
}

1;
