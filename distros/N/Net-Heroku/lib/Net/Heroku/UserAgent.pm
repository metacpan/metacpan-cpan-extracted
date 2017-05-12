package Net::Heroku::UserAgent;
use Mojo::Base 'Mojo::UserAgent';

has 'host';
has 'tx';
has 'api_key';

sub build_tx {
  my $self   = shift;
  my @params = @_;

  $self->tx($self->SUPER::build_tx(@params));

  # URL
  my $path = $self->tx->req->url->path;
  $self->tx->req->url(
    Mojo::URL->new(
          'https://:'
        . ($self->api_key || '') . '@'
        . $self->host
        . (substr($path, 0, 1) eq '/' ? '' : '/')    # optional slash
        . $path
    )
  );

  # Headers
  $self->tx->req->headers->header(Accept => 'application/json');

  return $self->tx;
}

1;

=head1 NAME

Net::Heroku::UserAgent

=head1 DESCRIPTION

Subclass of Mojo::UserAgent, making the host persistent

=head1 METHODS

Net::Heroku::UserAgent inherits all methods from Mojo::UserAgent and implements the following new ones.

=head2 build_tx

Builds a transaction using a persistently stored host
46:	hit eof while in pod documentation (no =cut seen)
	this can cause trouble with some pod utilities
