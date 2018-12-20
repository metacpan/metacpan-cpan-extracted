package Protocol::DBus::Path;

use strict;
use warnings;

use Protocol::DBus::Address ();

use constant _DEFAULT_SYSTEM_MESSAGE_BUS => 'unix:path=/var/run/dbus/system_bus_socket';

# NB: If this returns “autolaunch:”, then the system should use
# platform-specific methods of locating a running D-Bus session server,
# or starting one if a running instance cannot be found.
sub login_session_message_bus {
    my $addr = $ENV{'DBUS_SESSION_BUS_ADDRESS'};

    if (!$addr && ($^O eq 'darwin')) {
        my $path = $ENV{'DBUS_LAUNCHD_SESSION_BUS_SOCKET'};

        # OK, let’s *really* stretch …
        $path ||= readpipe( "launchctl getenv DBUS_LAUNCHD_SESSION_BUS_SOCKET" );
        chomp $path;

        if ($path) {
            chomp $path;

            $addr = "unix:path=$path";
        }
    }

    die "Found no login session message bus address!" if !$addr;

    return Protocol::DBus::Address::parse($addr);
}

sub system_message_bus {
    return Protocol::DBus::Address::parse( $ENV{'DBUS_SYSTEM_BUS_ADDRESS'} || _DEFAULT_SYSTEM_MESSAGE_BUS() );
}

1;
