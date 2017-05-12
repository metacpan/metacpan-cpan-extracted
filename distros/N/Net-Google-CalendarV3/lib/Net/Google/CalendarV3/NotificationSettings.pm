package Net::Google::CalendarV3::NotificationSettings;
$Net::Google::CalendarV3::NotificationSettings::VERSION = '0.16';
use Moose;
with 'Net::Google::CalendarV3::ToJson';
use Types::Standard qw( Str );

has [qw( type method )] => is => 'rw', isa => Str;

1;

