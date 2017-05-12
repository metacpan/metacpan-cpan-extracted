package System::InitD::Const;

=head1 NAME

System::InitD::Const

=head1 DESCRIPTION

Constants bundle for System::InitD package

=head1 CONSTANTS

=cut

use strict;
use warnings;

use base qw/Exporter/;

our @EXPORT = qw/
    DAEMON_ALREADY_RUNNING
    GRACE_RESTART_ALREADY_INPROGRESS
    GRACE_RESTART_NOT_ALLOWED
    DAEMON_IS_NOT_RUNNING
    STARTING
    STARTED
    RELOADING
    RELOADED
    NOT_STARTED
    STOPPING
    STOPPED
    NOT_STOPPED
    NEW_SUFFIX
/;

use constant DAEMON_ALREADY_RUNNING => "Daemon already running\n";
use constant GRACE_RESTART_ALREADY_INPROGRESS => "Reload already inprogress\n";
use constant DAEMON_IS_NOT_RUNNING  => "Daemon is not running\n";
use constant GRACE_RESTART_NOT_ALLOWED => "Grace Restart not allowed/not configured for this daemon\n";
use constant STARTING       =>  "Starting...\n";
use constant STARTED        =>  "Started.\n";
use constant RELOADING       =>  "Reloading...\n";
use constant RELOADED        =>  "Grace restart initiated (see 'info' or 'status' for progress).\n";
use constant NOT_STARTED    =>  "Not started: %s\n";
use constant STOPPING       =>  "Stopping...\n";
use constant STOPPED        =>  "Stopped.\n";
use constant NOT_STOPPED    =>  "Not stopped\n";

use constant NEW_SUFFIX     => ".new";

1;

__END__

