use strict;
use warnings;

use Data::Dumper;
use File::Temp qw/tempfile/;
use Cwd;

use Test::More tests => 7;

my $cwd = getcwd;
if ($cwd =~ m/t\/?$/s) {
    my @cwd = split '\/', $cwd;
    $cwd[$#cwd] = 'tmp';
    $cwd = join '/', @cwd;
}
else {
    $cwd .= '/tmp';
}

if (! -e $cwd) {
    mkdir $cwd or BAIL_OUT "Can't create tmp directory";
}
# 1: use System::InitD
use_ok 'System::InitD' or BAIL_OUT "Can't use System::InitD";

# 2: use System::InitD::Debian
use_ok 'System::InitD::GenInit::Debian' or BAIL_OUT "Can't use System::InitD::GenInit::Debian";

my $PROCESS_NAME   =  'SYSTEM_INITD_TEST_PROCESS';
my $TEMP_DIR       =  $cwd;

my $DAEMON_FILE    =  $cwd . '/daemon';
my $INIT_SCRIPT    =  $cwd . '/init_script';
my $PID_FILE       =  $cwd . '/test.pid';
my $RUNNING        =  "Daemon already running\n";
my $NOT_RUNNING    =  "Daemon is not running\n";

my $script = sprintf join ('', <DATA>), $^X, $PROCESS_NAME, $PID_FILE;
open DAEMON, '>', $DAEMON_FILE or BAIL_OUT "ERROR $!";;
chmod 0755, $DAEMON_FILE;
print DAEMON $script or BAIL_OUT "ERROR $!";
close DAEMON;

my $user = getpwuid($<);
$user ||= '';

my $options = {
    os              =>  'debian',
    target          =>  $INIT_SCRIPT,
    pid_file        =>  $PID_FILE,
    start_cmd       =>  $DAEMON_FILE . ' &',
    process_name    =>  $PROCESS_NAME,
    user            =>  $user,
};

require System::InitD::GenInit::Debian;
import System::InitD::GenInit::Debian;
System::InitD::GenInit::Debian->generate($options);
chmod 0755, $INIT_SCRIPT;

# 3:
ok -e $DAEMON_FILE && -s $DAEMON_FILE, 'Daemon file exists and not empty';

# 4:
ok -e $INIT_SCRIPT && -s $INIT_SCRIPT, 'Init script exists and not empty';

# 5:
is `$INIT_SCRIPT status`, $NOT_RUNNING, 'Not running';

system $INIT_SCRIPT, 'start';
sleep 2;

# 6:
ok -e $PID_FILE && -s $PID_FILE, 'PID file exists and not empty';

# 7:
my $res = `$INIT_SCRIPT status`;

is $res, $RUNNING, 'Running';

system "$INIT_SCRIPT", 'stop';

unlink $DAEMON_FILE;
unlink $INIT_SCRIPT;
unlink $PID_FILE;

done_testing();

__DATA__
#!%s
use strict;
use warnings;
fork and exit;
$0 = '%s';
open PID, '>', '%s';
print PID $$;
close PID;

eval {
    local $SIG{ALRM} = sub {
        die "ALARM!";
    };
    alarm 20;
    while (1) {
        sleep 1;
    }
} or do {
    die "Done";
};

1;
