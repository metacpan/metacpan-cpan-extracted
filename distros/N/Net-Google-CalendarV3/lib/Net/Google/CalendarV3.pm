package Net::Google::CalendarV3;
$Net::Google::CalendarV3::VERSION = '0.16';
=head NAME

Net::Google::CalendarV3 - Access Google Calendars using the v3 API

=cut

use Moose;
use Kavorka;
use Try::Tiny;
use Types::Standard qw( ArrayRef );
use Net::Google::CalendarV3::Types qw( CBool CalendarListEntry CalendarId Event to_Event );
use Net::Google::CalendarV3::Calendar;
use Net::Google::CalendarV3::Event;
use WWW::JSON;
use JSON::XS;

has authentication => is => 'ro', lazy => 1, predicate => 'has_auth', builder => '_build_authentication';
has oauth2_access_token => is => 'ro', predicate => 'has_token';

has calendars  => is => 'rw', default => sub { [] }, isa => ArrayRef[CalendarListEntry], coerce => 1;
has _service   => is => 'ro', lazy => 1, builder => '_build_service';
has _current_calendar => is => 'rw', isa => CalendarId, coerce => 1;

method _build_service {
    WWW::JSON->new( base_url         => 'https://www.googleapis.com/calendar/v3',
                    post_body_format => 'JSON',
                    ( $self->has_auth || $self->has_token ? (authentication   => $self->authentication) : () ),
                    json             => JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed,
    );
}

method _build_authentication {
    die "Need a valid OAuth2 access token"
        unless $self->has_token;
    my $token = $self->oauth2_access_token;
    return sub { $_[1]->header(Authorization => "Bearer $token") };
}

method get_calendars (CBool $owned?) {
    my $res = $self->_service->get('/users/me/calendarList', { minAccessRole => ($owned ? "owner" : "writer") } );
    die $res->error unless $res->success;
    $self->calendars($res->res->{items});
}

method set_calendar ($cal) {
    $self->_current_calendar($cal);
}

method get_events (%filters) {
    my $res = $self->_service->get('/calendars/[% calendarId %]/events', { -calendarId => $self->_current_calendar, %filters });
    die $res->error unless $res->success;
    my @items = @{ $res->res->{items} };
    while (my $pt = $res->res->{nextPageToken}) {
        $filters{pageToken} = $pt;
        $res = $self->_service->get('/calendars/[% calendarId %]/events', { -calendarId => $self->_current_calendar, %filters });
        push @items, @{ $res->res->{items} };
    }
    map { to_Event($_) } @items;
}

method get_entry ($entry_id) {
    my $res = $self->_service->get('/calendars/[% calendarId %]/events/[% eventId %]', { -calendarId => $self->_current_calendar, -eventId => $entry_id });
    die $res->error unless $res->success;
    to_Event( $res->res );
}

method add_entry ($entry) {
    $entry->{-calendarId} = $self->_current_calendar;
    my $res = $self->_service->post('/calendars/[% calendarId %]/events', $entry);
    die $res->error unless $res->success;
    $entry = to_Event($res->res);
}

method delete_entry ($entry) {
    my $res = $self->_service->delete('/calendars/[% calendarId %]/events/[% eventId %]', { -calendarId => $self->_current_calendar, -eventId => $entry->id });
    die $res->error unless $res->success or $res->code eq '404' or $res->code eq '410';
    1;
}

method update_entry ($entry) {
    $entry->{-calendarId} = $self->_current_calendar;
    $entry->{-eventId}    = $entry->id;
    my $res = $self->_service->put('/calendars/[% calendarId %]/events/[% eventId %]', $entry);
    die $res->error unless $res->success;
    $entry = to_Event($res->res);
}

method move_entry ($entry_id, $new_calendar_id) {
    my $res = $self->_service->post('/calendars/[% calendarId %]/events/[% eventId %]/move?destination=[% destination %]', { -calendarId => $self->_current_calendar, -eventId => $entry_id, -destination => $new_calendar_id });
    die $res->error unless $res->success;
    my $entry = to_Event($res->res);
}
1;

