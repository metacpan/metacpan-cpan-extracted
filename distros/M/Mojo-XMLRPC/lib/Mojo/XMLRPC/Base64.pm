package Mojo::XMLRPC::Base64;

use Mojo::Base -base;
use Mojo::Util;

use overload bool => sub {1}, '""' => sub { shift->encoded }, fallback => 1;

has 'encoded';

sub decoded {
  my $self = shift;
  if (@_) {
    $self->encoded(Mojo::Util::b64_encode($_[0], ''));
    return $self;
  }
  return Mojo::Util::b64_decode($self->encoded);
}

1;

