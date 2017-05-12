package Tak::WeakClient;

use Moo;

extends 'Tak::Client';

has service => (is => 'ro', required => 1, weak_ref => 1);

sub clone_or_self {
  my ($self) = @_;
  my $new = $self->service->clone_or_self;
  ($new ne $self->service
    ? 'Tak::Client'
    : ref($self))->new(service => $new, curried => [ @{$self->curried} ]);
}
    

1;
