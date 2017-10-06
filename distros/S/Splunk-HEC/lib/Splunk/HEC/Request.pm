package Splunk::HEC::Request;
use Carp;
use Splunk::Base -base;
use Time::HiRes;
use Sys::Hostname;
use strict;

# These keys are all optional. Any key-value pairs that are not included in the event will be set to values defined for the token on the Splunk server.
# "time"  The event time. The default time format is epoch time format, in the format <sec>.<ms>. For example, 1433188255.500 indicates 1433188255 seconds and 500 milliseconds after epoch, or Monday, June 1, 2015, at 7:50:55 PM GMT.
# "host"  The host value to assign to the event data. This is typically the hostname of the client from which you're sending data.
# "source"  The source value to assign to the event data. For example, if you're sending data from an app you're developing, you could set this key to the name of the app.
# "sourcetype"  The sourcetype value to assign to the event data.
# "index" The name of the index by which the event data is to be indexed. The index you specify here must within the list of allowed indexes if the token has the indexes parameter set.
# "fields"  (Not applicable to raw data.) Specifies a JSON object that contains explicit custom fields to be defined at index time. Requests containing the "fields" property must be sent to the /collector/event endpoint, or they will not be indexed. For more information, see Indexed field extractions.

has time => sub { return sprintf('%.3f', Time::HiRes::time()); };
has host => sub { return Sys::Hostname::hostname(); };
has source     => '';
has sourcetype => '';
has index      => '';
has fields     => '';
has event      => '';

sub TO_JSON {
  my $self = shift;
  Carp::croak('Splunk HEC requests must contain a valid event') unless $self->event;
  my %req = ();
  foreach my $attr ('time', 'host', 'source', 'sourcetype', 'index', 'fields', 'event') {
    my $value = $self->$attr;
    next unless $value;
    $req{$attr} = $value;
  }

  return \%req;
}

1;


=encoding utf8

=head1 NAME

Splunk::HEC::Request - An object wrapper for HEC events

=head1 SYNOPSIS

  use Splunk::HEC;
  use Splunk::HEC::Request;

  my $req = Splunk::HEC::Request->new(
    event => {
      message => 'Something happened',
      severity => 'INFO'
    }
  );

  my $hec = Splunk::HEC->new;
  my $res = $hec->send($req);
  if ($res->is_success)  { say $res->content }
  elsif ($res->is_error) { say $res->reason }

=head1 DESCRIPTION

L<Splunk::HEC::Request> is an object wrapper for HEC events

=head1 ATTRIBUTES

L<Splunk::HEC::Request> implements the following attributes.

=head2 event

  my $event = $req->event;
  $event   = $req->event('My event');

The actual HEC event payload sent to Splunk HEC. This can be
a string or HashRef. (required)

=head2 time

  my $time = $req->time;
  $time = $req->time('1505768576.379');

Timestamp (Epoch time) associated with event with millesecond precision.
Defaults to the current time (using L<Time::HiRes::time>). (not required)

=head2 host

  my $host = $req->host;
  $host = $req->host('myhost');

Hostname associated with the event. Defaults to the hostname of the
client. (not required)

=head2 source

  my $source = $req->source;
  $source = $req->source('datasource');

The source value to assign to the event data. For example, if you're sending data from an app
you're developing, you could set this key to the name of the app. (not required)

=head2 sourcetype

  my $type = $req->sourcetype;
  $type = $req->sourcetype('custom-sourcetype');

The sourcetype value to assign to the event data.
e.g. Use _json for JSON-based events (not required)

=head2 index

  my $index = $req->index;
  $index = $req->index('event-index');

The name of the index by which the event data is to be indexed. The index you specify
here must within the list of allowed indexes if the token
has the indexes parameter set. (not required)

=head2 fields

  my $fields = $req->fields;
  $fields = $req->fields({device => 'macbook', users => ['joe', 'bob']});

Specifies an object (HashRef) that contains explicit custom fields to be defined at index time.
Requests containing the "fields" property must be sent to the /collector/event endpoint,
or they will not be indexed. For more information,
see Splunk Indexed field extractions. (not required)

=head1 METHODS

L<Splunk::HEC::Request> implements the following methods.

=head2 new

  my $req = Splunk::HEC::Request->new;
  my $req = Splunk::HEC::Request->new(event => 'value');
  my $req = Splunk::HEC::Request->new({event => 'value'});

This is the constructor used to create the Splunk::HEC::Request object. You can
pass it either a hash or a hash reference with attribute values.

=head2 TO_JSON

  my $hash = $req->TO_JSON;

Returns a JSON encoding friendly hashref for use with L<JSON::XS>

=head1 SEE ALSO

L<Splunk::HEC::Request>, L<Splunk::HEC::Response>, L<Splunk::HEC>, L<HTTP::Tiny>, L<JSON::XS>

=cut

