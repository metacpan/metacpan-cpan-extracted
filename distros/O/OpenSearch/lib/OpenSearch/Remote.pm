package OpenSearch::Remote;
use strict;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Remote::Info;

sub info( $self, @params ) {
  return ( OpenSearch::Remote::Info->new(@params)->execute );
}

1;
