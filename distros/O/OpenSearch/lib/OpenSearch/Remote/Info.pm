package OpenSearch::Remote::Info;
use strict;
use warnings;
use feature qw(signatures);
use Moose;

has '_base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub execute($self) {
  my $res = $self->_base->_get( $self, [ '_remote', 'info' ] );
}

1;
