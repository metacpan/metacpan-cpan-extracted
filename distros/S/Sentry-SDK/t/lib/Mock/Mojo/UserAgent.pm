package Mock::Mojo::UserAgent;
use Mojo::Base -base, -signatures;

has requests => sub { [] };

sub post ($self, $url, $headers, $type, $body) {
  push $self->requests->@*,
    { url => $url, headers => $headers, type => $type, body => $body, };
}

1;
