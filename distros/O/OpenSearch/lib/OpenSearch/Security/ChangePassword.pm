package OpenSearch::Security::ChangePassword;
use strict;
use warnings;
use Moo;
use Types::Standard qw(InstanceOf);
use feature         qw(signatures);
no warnings qw(experimental::signatures);

with 'OpenSearch::Parameters::Security::ChangePassword';

has '_base' => (
  is       => 'rw',
  isa      => InstanceOf ['OpenSearch::Base'],
  required => 1,
);

sub execute($self) {
  my $res = $self->_base->_put( $self, [ '_plugins', '_security', 'api', 'account' ] );
}

1;
