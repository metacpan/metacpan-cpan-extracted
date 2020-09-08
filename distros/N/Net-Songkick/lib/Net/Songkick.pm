=head1 NAME

Net::Songkick - Perl wrapper for the Songkick API

=head1 SYNOPSIS

  use Net::Songkick;

  my $api_key = 'your_api_key';
  my $sk = Net::Songkick->new({ api_key => $api_key });

  # Returns XML by default
  my $events = $sk->get_events;

  # Or returns JSON
  my $events = $sk->get_events({ format => 'json' });

=head1 DESCRIPTION

This module presents a Perl wrapper around the Songkick API.

Songkick (L<http://www.songkick.com/>) is a web site that tracks gigs
around the world. Users can add information about gigs (both in the past
and the future) and can track their attendance at those gigs.

For more details of the Songkick API see L<https://www.songkick.com/developer>.

=head1 METHODS

=head2 Net::Songkick->new({ api_key => $api_key })

Creates a new object which can be used to request data from the Songkick
API. Requires one parameter which is the user's API key.

To request an API key from Songkick, see
L<https://www.songkick.com/api_key_requests/new>.

Returns a Net::Songkick object if successful.

=cut

package Net::Songkick;

use strict;
use warnings;

our $VERSION = '1.0.5';

use Moose;

use LWP::UserAgent;
use URI;
use JSON;

use Net::Songkick::Event;

has api_key => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has ua => (
  is => 'ro',
  isa => 'LWP::UserAgent',
  lazy_build => 1,
);

sub _build_ua {
  my $self = shift;

  return LWP::UserAgent->new;
}

has json_decoder => (
  is => 'ro',
  isa => 'JSON',
  lazy_build => 1,
);

sub _build_json_decoder {
  return JSON->new;
}

has ['api_format', 'return_format' ] => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_api_format {
  my $format = $_[0]->return_format;
  $format = 'json' if $format eq 'perl';
  return $format;
}

sub _build_return_format {
  return 'perl';
}

has ['api_url', 'events_url', 'user_events_url', 'user_gigs_url',
     'artists_url', 'artists_mb_url', 'venue_events_url', 'metro_url'] => (
  is => 'ro',
  isa => 'URI',
  lazy_build => 1,
);

sub _build_api_url {
  return URI->new('http://api.songkick.com/api/3.0');
}

sub _build_events_url {
  return URI->new(shift->api_url . '/events');
}

sub _build_user_events_url {
  return URI->new(shift->api_url . '/users/USERNAME/events');
}

sub _build_user_gigs_url {
  return URI->new(shift->api_url . '/users/USERNAME/gigography');
}

sub _build_artists_url {
  return URI->new(shift->api_url . '/artists/ARTIST_ID/calendar');
}

sub _build_artists_mb_url {
  return URI->new(shift->api_url . '/artists/mbid:MB_ID/calendar');
}

sub _build_venue_events_url {
  return URI->new(shift->api_url . '/venues/VENUE_ID/calendar');
}

sub _build_metro_url {
  return URI->new(shift->api_url . '/metro/METRO_ID/calendar');
}

has ['events_params', 'user_events_params', 'user_gigs_params',
     'artist_events_params', 'venue_events_params',
     'metro_events_params'] => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

sub _build_events_params {
  my @params = qw(type artists artist_name artist_id venue_id
                  min_date max_date location);

  return { map { $_ => 1 } @params };
}

sub _build_user_events_params {
  my @params = ( keys %{shift->events_params}, 'attendance' );

  return { map { $_ => 1 } @params };
}

sub _build_user_gigs_params {
  my @params = ( 'page' );

  return { map { $_ => 1 } @params };
}

sub _build_artist_events_params {
  my @params = qw[ min_date max_date page per_page order ];

  return { map { $_ => 1} @params };
}

sub _build_venue_events_params {
  my @params = qw[ page per_page ];

  return { map { $_ => 1 } @params };
}

sub _build_metro_events_params {
  my @params = qw[ page per_page ];

  return { map { $_ => 1 } @params };
}

sub _request {
  my $self = shift;
  my ($url, $args) = @_;

  $args->{apikey} = $self->api_key;
  $url->query_form($args) if $args;

  my $resp = $self->ua->get($url);

  return $resp->content if $resp->is_success;

  die $resp->content;
}

=head2 $sk->return_perl

Returns a Boolean value indicating whether or not this Net::Songkick
object should return Perl data structures for requests.

=cut

sub return_perl {
  return $_[0]->return_format eq 'perl';
}

=head2 $sk->parse_events_from_json($json_text)

Takes the JSON returns by a request for a list of events, parses the JSON
and returns a list of Net::Songkick::JSON objects.

=cut

sub parse_events_from_json {
  my $self = shift;
  my ($json) = @_;

  my @events;
  my $data = $self->json_decoder->decode($json);

  # Dump the two top levels of the JSON
  $data = $data->{resultsPage} if exists $data->{resultsPage};
  $data = $data->{results}     if exists $data->{results};

  if (exists $data->{event}) {
    # Ensure we have an array of events
    $data->{event} = [ $data->{event}] if ref $data->{event} ne 'ARRAY';

    @events = map { Net::Songkick::Event->new($_) } @{$data->{event}};
  } elsif (exists $data->{calendarEntry}) {
    $data->{calendarEntry} = [ $data->{calendarEntry} ]
      if ref $data->{calendarEntry} ne 'ARRAY';

    @events = map {
      Net::Songkick::Event->new($_->{event})
    } @{ $data->{calendarEntry} };
  } else {
    die "No events found in JSON\n" unless exists $data->{event};
  }

  return @events;
}

=head2 $sk->get_events({ ... options ... });

Gets a list of upcoming events from Songkick. Various parameters to control
the events returned are supported for the full list see
L<http://www.songkick.com/developer/event-search>.

In addition, this method takes an extra parameter, B<format>, which control
the format of the data returned. This can be either I<xml>, I<json> or
I<perl>. If it is either I<xml> or I<json> then the method will return the
raw XML or JSON from the Songkick API. If ii is I<perl> then this method
will return a list of L<Net::Songkick::Event> objects. If this parameter is
omitted, then I<perl> is assumed.

=cut

sub get_events {
  my $self = shift;
  my ($params) = @_;

  my $url = URI->new($self->events_url . '.' . $self->api_format);

  my %req_args;

  foreach (keys %$params) {
    if ($self->events_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

=head2 $sk->get_upcoming_events({ ... options ... });

Gets a list of upcoming events for a particular user from Songkick. This
method accepts all of the same search parameters as C<get_events>. It also
supports the optional B<format> parameter.

This method has another, mandatory, parameter called B<user>. This is the
username of the user that you want information about.

=cut

sub get_upcoming_events {
  my $self = shift;

  my ($params) = @_;

  my $user;
  if (exists $params->{user}) {
    $user = delete $params->{user};
  } else {
    die "user not passed to get_past_events\n";
  }

  my $url = $self->user_events_url . '.' . $self->api_format;
  $url =~ s/USERNAME/$user/;
  $url = URI->new($url);

  my %req_args;

  foreach (keys %$params) {
    if ($self->user_events_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

=head2 $sk->get_past_events({ ... options ... });

Gets a list of upcoming events for a particular user from Songkick.

This method has an optional parameter, B<page> to control which page of
the data you want to return. It also supports the B<format> parameter.

This method has another, mandatory, parameter called B<user>. This is the
username of the user that you want information about.

=cut

sub get_past_events {
  my $self = shift;

  my ($params) = @_;

  my $user;
  if (exists $params->{user}) {
    $user = delete $params->{user};
  } else {
    die "user not passed to get_past_events\n";
  }

  my $url = $self->user_gigs_url . '.' . $self->api_format;
  $url =~ s/USERNAME/$user/;
  $url = URI->new($url);

  my %req_args;

  foreach (keys %$params) {
    if ($self->user_gigs_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

=head2 $sk->get_venue_events({ ... options ...});

=cut

sub get_venue_events {
  my $self = shift;

  my ($params) = @_;

  my $url;

  if (exists $params->{venue_id}) {
    $url = $self->venue_events_url . '.' . $self->api_format;
    $url =~ s/VENUE_ID/$params->{venue_id}/;
  } else {
    die "No venue id passed to get_venue_events\n";
  }

  $url = URI->new($url);

  my %req_args;

  foreach (keys %$params) {
    if ($self->venue_events_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

=head2 $sk->get_artist_events({ ... options ... });

=cut

sub get_artist_events {
  my $self = shift;

  my ($params) = @_;

  my $url;

  if (exists $params->{artist_id}) {
    $url = $self->artists_url . '.' . $self->api_format;
    $url =~ s/ARTIST_ID/$params->{artist_id}/;
  } elsif (exists $params->{mb_id}) {
    $url = $self->artists_mb_url . '.' . $self->api_format;
    $url =~ s/MB_ID/$params->{mb_id}/;
  } else {
    die "No artist id or MusicBrainz id passed to get_artist_events\n";
  }

  $url = URI->new($url);

  my %req_args;

  foreach (keys %$params) {
    if ($self->artist_events_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

=head2 $sk->get_metro_events({ ... options ... });

=cut

sub get_metro_events {
  my $self = shift;

  my ($params) = @_;

  my $url;

  if (exists $params->{metro_id}) {
    $url = $self->metro_url . '.' . $self->api_format . '?api_key=' . $self->api_key;
    $url =~ s/METRO_ID/$params->{metro_id}/;
  } else {
    die "No metro area id passed to get_metro_events\n";
  }

  $url = URI->new($url);

  my %req_args;

  foreach (keys %$params) {
    if ($self->metro_events_params->{$_}) {
      $req_args{$_} = $params->{$_};
    }
  }

  my $resp = $self->_request($url, \%req_args);

  return $resp unless $self->return_perl;

  my @events = $self->parse_events_from_json($resp);

  return wantarray ? @events : \@events;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1), L<http://www.songkick.com/>, L<http://developer.songkick.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
