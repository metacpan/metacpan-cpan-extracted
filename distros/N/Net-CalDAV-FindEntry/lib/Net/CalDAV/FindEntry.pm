package Net::CalDAV::FindEntry 0.01;
use 5.020;
use experimental 'signatures';
use Carp 'croak';
use Net::CalDAVTalk;
use Net::CalDAV::Utils;
use Text::JSCalendar;

use Moo 2;

=head1 NAME

Net::CalDAV::FindEntry - find calendar entries overlapping a timespan

=head1 SYNOPSIS

  use 5.020;
  my $cal = Net::CalDAV::FindEntry->new(
      user         => 'AzureDiamond',
      password     => 'hunter2',
      calendar_url => 'https://example.com/calendar/',
  );
  if( 0 ) {
      $cal->ua->verify_SSL(0);
  }
  my @relevant_events = $cal->get_events(
      after    => '2026-09-01T09:00:00',
      before   => '2026-09-01T16:00:00',
      calendar => 'Work'
  );
  for ( sort { $a->{start} cmp $b->{start} } @relevant_events) {
      say(join( "-", $_->{start}, $_->{title} ));
  }

=cut

has ['user','password','calendar_url'] => (
    is => 'ro',
    required => 1,
);

has 'calendar' => (
    is => 'ro',
);

has 'cal' => (
    is => 'lazy',
    default => \&_get_calendar,
    handles => ['ua', 'logger'],
);

=head1 METHODS

=cut

sub _get_calendar($self, %options) {
    return Net::CalDAVTalk::Extended->new(
        user     => $options{ user }     // $self->user,
        password => $options{ password } // $self->password,
        url => $options{ calendar_url }  // $self->calendar_url,
        logger => sub { warn "DAV: @_" },
    );
}

# We need this filtering to account for events that start before our boundaries
# like whole-day events
sub event_overlaps( $start, $duration, $after, $before, $str=undef ) {
    my $starts_before_end = ($start le $before);
    my $ends_after_start = (dtend( $start, $duration) gt $after);
    #warn sprintf "%s - %s - %s - %s [%s] [%s] - %s", $after, $start, $before, dtend( $start, $duration ),
    #    $starts_before_end ? 'x' : ' ',
    #    $ends_after_start  ? 'x' : ' ',
    #    $str
    #    ;
    return
        $starts_before_end && $ends_after_start;
}

sub overlapping_events( $Events, $after, $before ) {
    my @relevant_events;

    # Filter the returned events for overlap
    EVENT: for my $e ($Events->@*) {
        my $title;
        my ($start, $duration);

        # For recurring events we want all events that somehow overlap with $after and $before
        if( scalar keys $e->{recurrenceOverrides}->%*) {
            my @matching = grep { event_overlaps( $_, $e->{recurrenceOverrides}->{$_}->{duration}, $after, $before, "" )
                                } sort { $a cmp $b } keys $e->{recurrenceOverrides}->%*;
            if( ! @matching ) {
                next EVENT;
            };
            for my $t ( @matching ) {
                $title //= $e->{recurrenceOverrides}->{$t}->{title};
                $start //= $t;
                $duration //= $e->{recurrenceOverrides}->{$t}->{duration};
            };
        };
        $title //= $e->{title};
        $start //= $e->{start};
        $duration //= $e->{duration};

        if( !event_overlaps( $start, $duration, $after, $before, $title )) {
            #warn "Ignoring '$title'";
            next EVENT;
        }

        push @relevant_events, {
            start => tslocal( $start ),
            title => $title,
            _e    => $e,
        };
    }
    return @relevant_events
}

sub get_events( $self, %args ) {

    my $before = $args{ before }
        or croak "Need 'before'";
    my $after = $args{ after }
        or croak "Need 'after'";
    my $calendar = $args{ calendar } // $self->calendar;

    # To also catch things that start (up to) two days before the current timestamp...
    my $_after = Text::JSCalendar::_wireDate($after)->add(days => -2)->strftime('%Y-%m-%dT%H:%M:%S');

    my @Events = $self->cal->GetEventsEx($calendar, after => $_after, before => $before)->@*;
    my @relevant_events = overlapping_events( \@Events, $after, $before );
}

package Net::CalDAVTalk::Extended 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

=head1 NAME

Net::CalDAVTalk::Extended - convenience functions and bugfixes for Net::CalDAVTalk

=cut

extends 'Net::CalDAVTalk';
use XML::Spice;
use URI::Escape qw(uri_unescape);
use Net::CalDAV::Utils;

=head1 METHODS

=head2 C<< ->GetEventLinksEx >>

  my $links = $cal->GetEventLinksEx( after => '...', before => '...' );

Allows filtering for events within a time range without truncating
the C<before> and C<after> values to whole days.

=cut

sub GetEventLinksEx {
  my ($Self, $calendarId, %Args) = @_;
  die "Need a calendarId" unless $calendarId;
  my @Extra;
  if ($Args{AlwaysRange} || $Args{after} || $Args{before}) {
    my $Start = Text::JSCalendar::_wireDate($Args{after} || die);
    my $End = Text::JSCalendar::_wireDate($Args{before} || die);
    push @Extra, x('C:time-range', {
      start => $Start->strftime('%Y%m%dT%H%M%SZ'),
      end   => $End->strftime('%Y%m%dT%H%M%SZ'),
    });
  }
  my $payload =     x('C:calendar-query', $Self->NS(),
      x('D:prop',
        x('D:getetag'),
      ),
      x('C:filter',
        x('C:comp-filter', { name => 'VCALENDAR' },
          x('C:comp-filter', { name => 'VEVENT' },
            @Extra,
          ),
        ),
      ),
    ),
  ;
  my $Response = $Self->Request(
    'REPORT',
    "$calendarId/",
    $payload,
    Depth => 1,
  );
  my (%Links, @Errors);
  my $NS_A = $Self->ns('A');
  my $NS_C = $Self->ns('C');
  my $NS_D = $Self->ns('D');
  foreach my $Response (@{$Response->{"{$NS_D}response"} || []}) {
    my $href = uri_unescape($Response->{"{$NS_D}href"}{content} // '');
    next unless $href;
    foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
      my $etag = $Propstat->{"{$NS_D}prop"}{"{$NS_D}getetag"}{content};
      $Links{$href} = $etag;
    }
  }
  return \%Links;
}

=head2 C<< ->GetEventsEx >>

Like C<< ->GetEvents >> but expands all recurrences to the actual timespan
instead of leaving that to the calling client. This requires RFC 4791
support by the CalDAV server.

=cut

# Copied from Net::CalDAVTalk, because we need to create a C:expand element
sub GetEventsEx($cal, $calendar, %Args) {
    my $urls = GetEventLinksEx($cal, $calendar, %Args);
    my $AnnotNames;
    my @Annotations;

    my (@Events, @Errors, %Links);
    if( $urls->%* ) {

        my %Args = ( start => $Args{ after } , end => $Args{before} );

        my $payload =
            x('C:calendar-multiget', $cal->NS(),
                x('D:prop',
                x('C:calendar-data',
                    x('C:expand', \%Args),
                    x('C:limit-recurrence-set', \%Args),
                ),
                x('D:getetag'),
                @Annotations,
                ),
                map { x('D:href', $_) } sort keys $urls->%*,
            );
        my $Response = $cal->Request(
            'REPORT',
            "$calendar/",
            $payload,
            Depth => 1,
        );

        my $NS_A = $cal->ns('A');
        my $NS_C = $cal->ns('C');
        my $NS_D = $cal->ns('D');
        for my $Response (@{$Response->{"{$NS_D}response"} || []}) {
          my $href = uri_unescape($Response->{"{$NS_D}href"}{content} // '');
          next unless $href;
          foreach my $Propstat (@{$Response->{"{$NS_D}propstat"} || []}) {
            my $etag = $Propstat->{"{$NS_D}prop"}{"{$NS_D}getetag"}{content};
            $Links{$href} = $etag;
            my $Prop = $Propstat->{"{$NS_D}prop"}{"{$NS_C}calendar-data"};
            my $Data = $Prop->{content};
            next unless $Data;
            my $Event;
            if ($Prop->{'-content-type'} and $Prop->{'-content-type'} =~ m{application/event\+json}) {
              # JSON event is in API format already
              $Event = eval { decode_json($Data) };
            }
            else {
              # returns an array, but there should only be one UID per file
              # Suppress property warnings here as JSCalendar raises otherwise
              # unsuppressible warnings :-/
              my $org_warn = $SIG{ __WARN__ };
              local $SIG{ __WARN__ } = sub {
                return if $_[0] =~ /DTEND and DURATION/;
                goto &$org_warn;
              };

              ($Event) = eval { $cal->vcalendarToEvents($Data) };
            }
            if ($@) {
              push @Errors, $@;
              next;
            }
            next unless $Event;
            if ($Args{Full}) {
              $Event->{_raw} = $Data;
            }
            $Event->{href} = $href;
            $Event->{id} = $cal->shortpath($href);
            foreach my $key (@$AnnotNames) {
              my $propns = $NS_C;
              my $name = $key;
              if ($key =~ m/(.*):(.*)/) {
                $name = $2;
                $propns = $cal->ns($1);
              }
              my $AData = $Propstat->{"{$NS_D}prop"}{"{$propns}$name"}{content};
              next unless $AData;
              $Event->{annotation}{$name} = $AData;
            }
            push @Events, $Event;
          }
        }
    }
    return wantarray ? (\@Events, \@Errors) : \@Events;
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Net-CalDAV-FindEntry>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Net-CalDAV-FindEntry/issues>


=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
