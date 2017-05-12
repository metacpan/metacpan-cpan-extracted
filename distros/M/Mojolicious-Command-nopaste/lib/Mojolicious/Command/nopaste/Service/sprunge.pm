package Mojolicious::Command::nopaste::Service::sprunge;
use Mojo::Base 'Mojolicious::Command::nopaste::Service';

has description => "Post to sprunge.us\n";

sub paste {
  my $self = shift;

  my $tx = $self->ua->post( 
    'http://sprunge.us', 
    form => { sprunge => $self->text },
  );

  unless ($tx->res->is_success) {
    say $tx->res->message;
    say $tx->res->body;
    exit 1;
  }

  chomp( my $url = $tx->res->body );

  if (my $lang = $self->language) {
    $url .= "?$lang";
  }
  return $url;
}

1;

