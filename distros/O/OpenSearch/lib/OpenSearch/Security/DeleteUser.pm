package OpenSearch::Security::DeleteUser;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature         qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Security::DeleteUser';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf ['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_delete( $self, [ '_plugins', '_security', 'api', 'internalusers', $self->username ] );
}

1;
