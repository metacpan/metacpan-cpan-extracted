package Net::Google::CalendarV3::Types;
$Net::Google::CalendarV3::Types::VERSION = '0.16';
use Type::Library
   -base,
   -declare => qw(  DefaultReminder NotificationSettings ListOfNotificationSettings
                    CalendarListEntry Person Attendee Date CalendarId
                    Event
                    DateTime
                    CBool
                );
use Type::Utils -all;
use Types::Standard -types;

class_type DefaultReminder,         { class => 'Net::Google::CalendarV3::DefaultReminder' };
class_type NotificationSettings,    { class => 'Net::Google::CalendarV3::NotificationSettings' };
class_type CalendarListEntry,       { class => 'Net::Google::CalendarV3::Calendar' };
class_type Person,                  { class => 'Net::Google::CalendarV3::Person' };
class_type Attendee,                { class => 'Net::Google::CalendarV3::Attendee' };
class_type Date,                    { class => 'Net::Google::CalendarV3::Date' };
class_type Event,                   { class => 'Net::Google::CalendarV3::Event' };
class_type DateTime,                { class => 'DateTime' };

declare ListOfNotificationSettings,
  as ArrayRef[NotificationSettings];

declare CBool, as Bool, where { !!$_ || !$_ };

declare CalendarId, as Str, where { 1 };

coerce CBool,
    from Any, via { !!$_ };
coerce CalendarId,
    from CalendarListEntry, via { $_->id };
coerce CalendarId,
    from Str, via { $_ };
coerce DefaultReminder,
    from HashRef, via { 'Net::Google::CalendarV3::DefaultReminder'->new($_) };
coerce NotificationSettings,
    from HashRef, via { 'Net::Google::CalendarV3::NotificationSettings'->new($_) };
coerce CalendarListEntry,
    from HashRef, via { 'Net::Google::CalendarV3::Calendar'->new($_) };
coerce Person,
    from HashRef, via { 'Net::Google::CalendarV3::Person'->new($_) };
coerce Attendee,
    from HashRef, via { 'Net::Google::CalendarV3::Attendee'->new($_) };
coerce Date,
    from HashRef, via { 'Net::Google::CalendarV3::Date'->new($_) };
coerce Event,
    from HashRef, via { 'Net::Google::CalendarV3::Event'->new($_) };

coerce ListOfNotificationSettings,
    from HashRef, via { [ map { to_NotificationSettings($_) } @{ $_->{notifications} } ] };

1;

