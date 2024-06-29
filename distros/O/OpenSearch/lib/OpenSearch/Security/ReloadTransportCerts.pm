package OpenSearch::Security::ReloadTransportCerts;
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
  my $res = $self->_base->_put( $self, [ '_plugins', '_security', 'api', 'ssl', 'transport', 'reloadcerts' ] );
}

1;
