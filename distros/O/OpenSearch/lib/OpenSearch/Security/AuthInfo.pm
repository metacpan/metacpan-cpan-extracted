package OpenSearch::Security::AuthInfo;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature         qw(signatures);
no warnings qw(experimental::signatures);

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf ['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_get( $self, [ '_plugins', '_security', 'authinfo' ] );
}

1;
