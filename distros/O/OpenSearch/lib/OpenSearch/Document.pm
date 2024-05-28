package OpenSearch::Document;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Document::Index;

sub index( $self, @params ) {
  return ( OpenSearch::Document::Index->new(@params)->execute );
}

1;
