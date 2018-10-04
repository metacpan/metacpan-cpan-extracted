package Protocol::DBus::Path;

use strict;
use warnings;

use constant _DEFAULT_SYSTEM_MESSAGE_BUS => 'unix:path=/var/run/dbus/system_bus_socket';

# NB: If this returns “autolaunch:”, then the system should use
# platform-specific methods of locating a running D-Bus session server,
# or starting one if a running instance cannot be found.
sub login_session_message_bus { $ENV{'DBUS_SESSION_BUS_ADDRESS'} }

sub system_message_bus {
    $ENV{'DBUS_SYSTEM_BUS_ADDRESS'} || _DEFAULT_SYSTEM_MESSAGE_BUS();
}

1;
