package Splunk::HEC;
use Carp;
use JSON::XS;
use HTTP::Tiny;
use Splunk::Base -base;
use Splunk::HEC::Request;
use Splunk::HEC::Response;
use strict;

our $VERSION = '1.02';

has url   => sub { return $ENV{SPLUNK_HEC_URL}   || 'http://localhost:8088/services/collector'; };
has token => sub { return $ENV{SPLUNK_HEC_TOKEN} || '' };
has agent => sub { return $ENV{SPLUNK_HEC_AGENT} || "perl-splunk-hec/$VERSION"; };
has timeout => sub { return $ENV{SPLUNK_HEC_TIMEOUT} || 60 };
has max_retries => 0;

sub client {
  my $self = shift;
  my %args = @_;
  return $self->{_client} if $self->{_client};

  my %options = (
    agent   => $args{agent}   || $self->agent,
    timeout => $args{timeout} || $self->timeout,
    default_headers => {'Content-Type' => 'application/json'}
  );

  Carp::croak('A valid Splunk HEC token is required for authentication') unless $self->token;

  $options{default_headers}->{'Authorization'} = join(' ', 'Splunk', $self->token);

  return $self->{_client} = HTTP::Tiny->new(%options);
}

# These keys are all optional. Any key-value pairs that are not included in the event will be set to values defined for the token on the Splunk server.
# "time"  The event time. The default time format is epoch time format, in the format <sec>.<ms>. For example, 1433188255.500 indicates 1433188255 seconds and 500 milliseconds after epoch, or Monday, June 1, 2015, at 7:50:55 PM GMT.
# "host"  The host value to assign to the event data. This is typically the hostname of the client from which you're sending data.
# "source"  The source value to assign to the event data. For example, if you're sending data from an app you're developing, you could set this key to the name of the app.
# "sourcetype"  The sourcetype value to assign to the event data.
# "index" The name of the index by which the event data is to be indexed. The index you specify here must within the list of allowed indexes if the token has the indexes parameter set.
# "fields"  (Not applicable to raw data.) Specifies a JSON object that contains explicit custom fields to be defined at index time. Requests containing the "fields" property must be sent to the /collector/event endpoint, or they will not be indexed. For more information, see Indexed field extractions.

sub send {
  my $self = shift;
  Carp::croak('At least one Splunk HEC event is required.') unless @_;

# a couple ways to call send
# NOTE: Only event is required
# HASH - (single event) send(event => {}, time => $epoch, source => 'datasource', sourcetype => '', index => 'data-index', fields...)
# ARRAY - (many events) send({}, {}, {})
# ARRAYREF - (many events) send([{}, {}, {}])
  my @requests = ();

  if (@_ > 1) {

    # array of objects
    if (ref($_[0]) eq 'HASH') {
      map { push(@requests, Splunk::HEC::Request->new(%{$_})); } @_;
    }
    else {
      push(@requests, Splunk::HEC::Request->new(@_));
    }
  }
  elsif (ref($_[0]) eq 'HASH') {
    push(@requests, Splunk::HEC::Request->new(%{$_[0]}));
  }
  elsif (ref($_[0]) eq 'ARRAY') {
    map { push(@requests, Splunk::HEC::Request->new(%{$_})); } @{$_[0]};
  }

  my $response = $self->client()->post(
    $self->url => {
      content => sub {
        return unless @requests;
        my $req = shift @requests;
        return unless $req;
        my $json = JSON::XS->new->convert_blessed(1)->encode($req);
        return (@requests) ? $json . "\n" : $json;
      }
    }
  );

  return Splunk::HEC::Response->new(success => 0, code => 500, reason => 'Unknown Server Error')
    unless $response;

  my $content_type = $response->{headers}->{'content-type'};
  if ($response && $response->{content} && $content_type =~ /json/i) {
    $response->{content} = JSON::XS::decode_json($response->{content});
  }

  return Splunk::HEC::Response->new(%{$response});
}

1;

=encoding utf8

=head1 NAME

Splunk::HEC - A simple wrapper for the Splunk HTTP Event Collector (HEC) API

=head1 SYNOPSIS

  use Splunk::HEC;

  my $hec = Splunk::HEC->new(
    url => 'https://mysplunkserver.example.com:8088/services/collector/event',
    token => '12345678-1234-1234-1234-1234567890AB'
  );

  my $res = $hec->send(event => {message => 'Something happened', severity => 'INFO'});
  if ($res->is_success)  { say $res->content }
  elsif ($res->is_error) { say $res->reason }

=head1 DESCRIPTION

L<Splunk::HEC> is a simple HTTP client wrapper for the Splunk HEC API;

=head1 ATTRIBUTES

L<Splunk::HEC> implements the following attributes.

=head2 url

  my $url = $hec->url;
  $url   = $hec->url('https://mysplunkserver.example.com:8088/services/collector/event');

Full URL to Splunk HEC endpoint (required).

=head2 token

  my $token = $hec->token;
  $token   = $hec->token('12345678-1234-1234-1234-1234567890AB');

Splunk HEC authentication token (required)

=head2 timeout

  my $timeout = $hec->timeout;
  $timeout = $hec->timeout(300);

Timeout in seconds when talking to Splunk HEC. (optional, default 60s)

=head1 METHODS

L<Splunk::HEC> implements the following methods.

=head2 new

  my $hec = Splunk::HEC->new;
  my $hec = Splunk::HEC->new(url => 'value', token => 'value');
  my $hec = Splunk::HEC->new({name => 'value'});

This is the constructor used to create the Splunk::HEC object. You can
pass it either a hash or a hash reference with attribute values.

=head2 send

  # single event
  $res = $hec->send(event => 'event1', time => $epoch, source => 'datasource', sourcetype => '', index => 'data-index');

  # multiple events (array of hashrefs)
  $res = $hec->send(
    {event => 'event1', time => $epoch, source => 'datasource', sourcetype => '', index => 'data-index'},
    {event => 'event2', time => $epoch, source => 'datasource', sourcetype => '', index => 'data-index'}
  );

Send one or more events to HEC. If multiple events are provided at once, they
are sent using HEC batch mode. Passed events are converted into L<Splunk::HEC::Request>
objects prior to being encoded and sent. Once HEC responds, it returns a
L<Splunk::HEC::Response> object.

See the attributes of L<Splunk::HEC::Request> for supported event attributes and default
settings.

=head2 client

  my $hec = Splunk::HEC->new;
  my $client = $hec->client;

Returns the HTTP client

=head1 ENVIRONMENT VARIABLES

L<Splunk::HEC> provides configuration via the following environment variables.

=head2 SPLUNK_HEC_URL

Full URL to Splunk HEC endpoint (required).

=head2 SPLUNK_HEC_TOKEN

Splunk HEC authentication token (required)

=head2 SPLUNK_HEC_TIMEOUT

Timeout in seconds when talking to Splunk HEC. (optional, default 60s)

=head1 SEE ALSO

L<Splunk::HEC::Request>, L<Splunk::HEC::Response>, L<Splunk::HEC>, L<HTTP::Tiny>, L<JSON::XS>

=cut
