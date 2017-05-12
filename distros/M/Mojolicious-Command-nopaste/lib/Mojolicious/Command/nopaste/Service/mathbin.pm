package Mojolicious::Command::nopaste::Service::mathbin;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';

has description => "Post to mathb.in\n";

sub paste {
  my $self = shift;

  my $name  = $self->name;
  my $title = $self->desc;

  my $tx = $self->ua->post( 'http://mathb.in' => form => {
    code    => $self->text,
    ( $name  ? ( name  => $name  ) : () ),
    secrecy => $self->private ? 'yes' : '',
    ( $title ? ( title => $title ) : () ),
  });

  unless ($tx->res->is_success) {
    say $tx->res->message;
    say $tx->res->body;
    exit 1;
  }

  return $tx->req->url;
}

1;

