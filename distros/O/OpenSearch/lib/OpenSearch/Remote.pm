package OpenSearch::Remote;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use Data::Dumper;
use OpenSearch::Remote::Info;
use feature qw(signatures);
no warnings qw(experimental::signatures);

has '_base' => (
  is  => 'rw',
  isa => InstanceOf['OpenSearch::Base'],
  required => 1,
);

sub info( $self, @params ) {
  return ( OpenSearch::Remote::Info->new(@params, _base => $self->_base)->execute );
}

1;
