package Mock::Mojo::UserAgent;
use Mojo::Base -base, -signatures;

use Mock::Mojo::Request;
use Mock::Mojo::Response;
use Mock::Mojo::Transaction;

has requests => sub { [] };

sub post ($self, $url, $headers, @payload) {
  push $self->requests->@*,
    { url => $url, headers => $headers, body => $payload[-1], };

  return Mock::Mojo::Transaction->new(
    req => Mock::Mojo::Request->new,
    res => Mock::Mojo::Response->new,
  );
}

1;
