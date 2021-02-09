package Sentry::Envelope;
use Mojo::Base -base, -signatures;

use Mojo::JSON qw(encode_json);

has event_id     => undef;
has headers      => sub ($self) { { event_id => $self->event_id } };
has body         => sub { {} };
has sample_rates => sub { [{ id => "client_rate", rate => "1" }] };    # FIXME
has type         => 'transaction';
has item_headers =>
  sub ($self) { { type => $self->type, sample_rates => $self->sample_rates } };

sub serialize ($self) {
  my @lines = ($self->headers, $self->item_headers, $self->body);
  return join("\n", map { encode_json($_) } @lines);
}

1;
