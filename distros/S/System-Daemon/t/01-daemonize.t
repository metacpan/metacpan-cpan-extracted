use strict;
use warnings;

no warnings qw/once/;
use POSIX;
use Data::Dumper;

use Test::More;

use System::Process;

eval {
    require System::Daemon;
    import System::Daemon;
    1;
} or do {
    BAIL_OUT("Use failed.");
};

$System::Daemon::Utils::DEBUG = 1;

my $dir = getcwd();
$dir .= '/test_daemon.pid';

print "Dir: ", $dir, "\n";

my %test_params = (
    pidfile => $dir,
);

my $start_pid = $$;
my $daemon = System::Daemon->new(%test_params);
eval {$daemon->daemonize(); 1;} or do {
    BAIL_OUT("Can't daemonize: $@ !");
};

my $sp = $daemon->process_object();

ok($start_pid ne $sp->pid(), "Daemonized ok master pid: $start_pid daemon pid: $sp->{pid}");

my $daemon_pid = System::Daemon::Utils::read_pid($test_params{pidfile});

ok($sp->pid() eq $daemon_pid, "PID file ok");
$daemon->cleanup();
ok(!-e $test_params{pidfile}, "PID file successfully removed");
done_testing();
$daemon->exit(0);
# performing self-tests


