package Sentry::Transport::Http;
use Mojo::Base -base, -signatures;

use HTTP::Status qw(:constants);
use Mojo::JSON 'encode_json';
use Mojo::UserAgent;
use Mojo::Util 'dumper';
use Readonly;
use Sentry::Envelope;
use Sentry::Hub;
use Sentry::Logger 'logger';

Readonly my $SENTRY_API_VERSION => '7';

has _http => sub {
  Mojo::UserAgent->new(request_timeout => 5, connect_timeout => 1);
};
has _sentry_client => 'perl-sentry/1.0';
has _headers       => sub ($self) {
  my @header = (
    "Sentry sentry_version=$SENTRY_API_VERSION",
    "sentry_client=" . $self->_sentry_client,
    'sentry_key=' . $self->dsn->user,
  );

  my $pass = $self->dsn->pass;
  push @header, "sentry_secret=$pass" if $pass;

  return {
    'Content-Type'  => 'application/json',
    'X-Sentry-Auth' => join(', ', @header),
  };
};
has _sentry_url => sub ($self) {
  my $dsn = $self->dsn;
  die 'DSN missing' unless $dsn;

  return sprintf('%s://%s:%d/api/%d',
    $dsn->protocol, $dsn->host, $dsn->port, $dsn->project_id);
};
has dsn => undef;

sub send ($self, $payload) {
  my $is_transaction = ($payload->{type} // '') eq 'transaction';
  my $endpoint       = $is_transaction ? 'envelope' : 'store';
  my $tx;
  my $url = $self->_sentry_url . "/$endpoint/";

  if ($is_transaction) {
    my $envelope = Sentry::Envelope->new(
      event_id => $payload->{event_id},
      body     => $payload,
    );
    $payload = $envelope->serialize;
    $tx      = $self->_http->post($url => $self->_headers, $payload);
  } else {
    $tx = $self->_http->post($url => $self->_headers, json => $payload);
  }

  logger->log(
    sprintf(
      qq{Sentry request done. Payload: \n<<<<<<<<<<<<<<\n%s\n<<<<<<<<<<<<<<\nCode: %s},
      $tx->req->body, $tx->res->code // 'ERROR'
    ),
    __PACKAGE__
  );

  if (!defined $tx->res->code || $tx->res->is_error) {
    logger->warn('Error: ' . ($tx->res->error // {})->{message});
    return;
  }

  if ($tx->res->code == HTTP_BAD_REQUEST) {
    logger->error($tx->res->body);
  }

  return $tx->res->json;
}

1;
