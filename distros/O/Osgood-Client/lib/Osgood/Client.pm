package Osgood::Client;
use Moose;

use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Moose::Util::TypeConstraints;
use Osgood::EventList;
use Osgood::Event;
use URI;

subtype 'Osgood.Client.URI' => as class_type('URI');
coerce 'Osgood.Client.URI'
    => from Str
    => via { URI->new($_, 'http') };

has 'error' => ( is => 'rw', isa => 'Str' );
has 'url' => (
    is => 'rw',
    isa => 'Osgood.Client.URI',
    default => sub { URI->new('http://localhost') },
    coerce => 1
);
has 'list' => ( is => 'rw', isa => 'Maybe[Osgood::EventList]' );
has 'timeout' => ( is => 'rw', isa => 'Int', predicate => 'has_timeout' );

our $VERSION = '2.0.7';
our $AUTHORITY = 'cpan:GPHAT';

=head1 NAME

Osgood::Client - Client for the Osgood Passive, Persistent Event Queue

=head1 DESCRIPTION

Provides a client for sending events to or retrieving events from an Osgood
queue.

=head1 SYNOPSIS

To send some events:

  my $event = Osgood::Event->new(
      object => 'Moose',
      action => 'farted',
      date_occurred => DateTime->now
  );
  my $list = Osgood::EventList->new(events => [ $event ])
  my $client = Osgood::Client->new(
      url => 'http://localhost',
      list => $list
  );
  my $retval = $client->send;
  if($list->size == $retval) {
      print "Success :)\n";
  } else {
      print "Failure :(\n";
  }

To query for events

  use DateTime;
  use Osgood::Client;
  use URI;

  my $client = Osgood::Client->new(
      url => URI->new('http://localhost:3000'),
  );
  $client->query({ object => 'Moose', action => 'farted' });
  if($client->list->size == 1) {
      print "Success\n";
  } else {
      print "Failure\n";
  }

=head1 METHODS

=head2 new

Creates a new Osgood::Client object.

=head2 list

Set/Get the EventList.  For sending events, you should set this.  For
retrieving them, this will be populated by query returns.

=head2 send

Send events to the server.

=cut
sub send {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new;
    if($self->has_timeout) {
        $ua->timeout($self->timeout);
    }

    my $req = HTTP::Request->new(POST => $self->url->canonical.'/event');
    $req->content_type('application/json');
    $req->content($self->list->freeze);

    my $res = $ua->request($req);

    if($res->is_success) {
        my $data = JSON::XS->new->decode($res->content);
        if(!defined($data) || !(ref($data) eq 'HASH')) {
            $self->error('Unable to parse JSON response');
            return 0;
        }
        my $count = $data->{count};
        if($data->{error}) {
            $self->error($data->error);
        }

        return $count;
    } else {
        $self->error($res->status_line);
        return 0;
    }
}

=head2 query

Query the Osgood server for events.  Takes a hashref in the following format:

  {
    id => X,
    object => 'obj',
    action => 'foo',
    date => '2007-12-11'
  }

At least one key is required.

A true or false value is returned to denote the success of failure of the
query.  If false, then the error will be set in the error accessor.  On
success the list may be retrived from the list accessor.

Implicitly sets $self->list(undef), to clear previous results.

=cut

sub query {
    my ($self, $params) = @_;

    $self->list(undef);

    if((ref($params) ne 'HASH') || !scalar(keys(%{ $params }))) {
        die('Must supply a hash of parameters to query.');
    }

    my $ua = LWP::UserAgent->new;
    if($self->has_timeout) {
        $ua->timeout($self->timeout);
    }

    my $evtparams = delete($params->{params}) || {};
    my $query = join('&',
        map({ "$_=".$params->{$_} } keys(%{ $params })),
        map({ "parameter.$_=$evtparams->{$_}" } keys %$evtparams)
    );

    my $req = HTTP::Request->new(GET => $self->url->canonical.'/event?'.$query);

    my $res = $ua->request($req);

    if($res->is_success) {
        $self->list(Osgood::EventList->thaw($res->content));
        return 1;
    } else {
        $self->error($res->status_line);
        return 0;
    }
}

=head2 timeout

The number of seconds to wait before timing out.

=head2 url

The url of the Osgood queue we should contact.  Expects an instance of URI.

=head2 error

Returns the error message (if there was one) for this client.  This should
be called if C<query> or C<send> do not return what you expect.

=head1 PERFORMANCE

Originally Osgood used a combination of XML::DOM and XML::XPath for
serialization.  After some testing it has switched to using JSON, as JSON::XS
is considerably faster.  In tests on my machine (dual quad-core xeon) it takes
about 10 seconds to deserialize 10_000 simple events.

Please keep in mind that the sending of events will also have a cost, as
insertion into the database takes time.  See the accompanying PERFORMANCE
section of L<Osgood::Server>.

=head1 AUTHOR

Cory 'G' Watson <gphat@cpan.org>

=head1 CONTRIBUTORS

Mike Eldridge (diz)

=head1 SEE ALSO

perl(1), Osgood::Event, Osgood::EventList

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Magazines.com, LLC

You can redistribute and/or modify this code under the same terms as Perl
itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
