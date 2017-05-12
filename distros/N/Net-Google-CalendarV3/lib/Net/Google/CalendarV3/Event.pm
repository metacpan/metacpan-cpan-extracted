package Net::Google::CalendarV3::Event;
$Net::Google::CalendarV3::Event::VERSION = '0.16';
use Moose;
with 'Net::Google::CalendarV3::ToJson';
use Kavorka qw(method multi);
use Try::Tiny;
use Net::Google::CalendarV3::Attendee;
use Net::Google::CalendarV3::Date;
use Net::Google::CalendarV3::Person;
use Types::Standard qw( Str Int ArrayRef Enum);
use Net::Google::CalendarV3::Types qw( CBool Person Attendee Date DateTime );

has [ qw( kind etag creator organizer attendees created
        endTimeUnspecified gadget
        hangoutLink htmlLink iCalUID locked originalStartTime
        privateCopy recurringEventId reminders source start end
        updated
    ) ], is => 'ro';
has [ qw( anyoneCanAddSelf attendeesOmitted colorId description
        extendedProperties guestsCanInviteOthers guestsCanSeeOtherGuests
        id location recurrence sequence status summary
        transparency visibility
    ) ], is => 'rw';

has '+kind' => default => 'calendar#event';

has [ qw( +creator +organizer ) ], isa => Person, coerce => 1;
has '+attendees', isa => ArrayRef[Attendee], coerce => 1;
has [ qw( +anyoneCanAddSelf +attendeesOmitted
        +guestsCanInviteOthers +guestsCanSeeOtherGuests
        +locked +privateCopy
    ) ], isa => CBool, coerce => 1;

has [qw( +start +end +originalStartTime )], isa => Date, coerce => 1, lazy => 1, builder => '_build_empty_date';
method _build_empty_date { Net::Google::CalendarV3::Date->new }

has '+status',       isa => Enum[qw(confirmed tentative cancelled)];
has '+transparency', isa => Enum[qw(opaque transparent)];
has '+visibility',   isa => Enum[qw(default public private confidential)];

# compatibility methods for Net::Google::Calendar::Entry

method uid { $self->id }

multi method title ($title) {
    $self->summary($title);
}

multi method title () {
    $self->summary;
}

multi method content ($content) {
    $self->description($content);
}

multi method content () {
    $self->description;
}

multi method when (DateTime $start, DateTime $end, CBool $is_all_day) {
    $self->start->set($start, $is_all_day);
    $self->end->set($end, $is_all_day);
}

multi method when () {
    my ($start_dt, $start_all_day) = $self->start->get();
    my ($end_dt, $end_all_day) = $self->end->get();
    return ($start_dt, $end_dt, $start_all_day && $end_all_day);
}

=pod
{
  "kind": "calendar#event",
  "etag": etag,
  "id": string,
  "status": string,
  "htmlLink": string,
  "created": datetime,
  "updated": datetime,
  "summary": string,
  "description": string,
  "location": string,
  "colorId": string,
  "creator": {
    "id": string,
    "email": string,
    "displayName": string,
    "self": boolean
  },
  "organizer": {
    "id": string,
    "email": string,
    "displayName": string,
    "self": boolean
  },
  "start": {
    "date": date,
    "dateTime": datetime,
    "timeZone": string
  },
  "end": {
    "date": date,
    "dateTime": datetime,
    "timeZone": string
  },
  "endTimeUnspecified": boolean,
  "recurrence": [
    string
  ],
  "recurringEventId": string,
  "originalStartTime": {
    "date": date,
    "dateTime": datetime,
    "timeZone": string
  },
  "transparency": string,
  "visibility": string,
  "iCalUID": string,
  "sequence": integer,
  "attendees": [
    {
      "id": string,
      "email": string,
      "displayName": string,
      "organizer": boolean,
      "self": boolean,
      "resource": boolean,
      "optional": boolean,
      "responseStatus": string,
      "comment": string,
      "additionalGuests": integer
    }
  ],
  "attendeesOmitted": boolean,
  "extendedProperties": {
    "private": {
      (key): string
    },
    "shared": {
      (key): string
    }
  },
  "hangoutLink": string,
  "gadget": {
    "type": string,
    "title": string,
    "link": string,
    "iconLink": string,
    "width": integer,
    "height": integer,
    "display": string,
    "preferences": {
      (key): string
    }
  },
  "anyoneCanAddSelf": boolean,
  "guestsCanInviteOthers": boolean,
  "guestsCanModify": boolean,
  "guestsCanSeeOtherGuests": boolean,
  "privateCopy": boolean,
  "locked": boolean,
  "reminders": {
    "useDefault": boolean,
    "overrides": [
      {
        "method": string,
        "minutes": integer
      }
    ]
  },
  "source": {
    "url": string,
    "title": string
  }
}
=cut

1;

