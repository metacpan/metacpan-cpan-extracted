use strict;
use warnings;

use vars qw( $D_BASE $T_BASE );
use vars qw( $CFG_FILE $PORT $KNOWN_HOSTS $IDENTITY $PSSHD $PID_FILE
             $USER_AUTHORIZED_KEYS $DUMMY_PASSWD );

use Cwd;
my $pwd = cwd();
my @pieces = split /\//, $pwd;
if (-f "test-common.pl") {      # Need to move up one dir.
    pop @pieces;
}
elsif (-f "t/test-common.pl") { # Already in the right dir.
}
$D_BASE = join '/', @pieces;
$T_BASE = "$D_BASE/t";

$CFG_FILE = "$T_BASE/config";
$PORT = 60000;
$KNOWN_HOSTS = "$T_BASE/t_known_hosts";
$IDENTITY = "$T_BASE/identity";
$PSSHD = "$T_BASE/psshd";
$PID_FILE = "$T_BASE/psshd_pid";
$USER_AUTHORIZED_KEYS = "$T_BASE/authorized_keys";
$DUMMY_PASSWD = "dummy";

1;
