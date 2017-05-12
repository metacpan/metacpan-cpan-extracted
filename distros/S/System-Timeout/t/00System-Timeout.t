use Test::More tests => 9;
BEGIN { use_ok('System::Timeout') };
use System::Timeout qw(system timeout);

my $s = time;
my $r = system(3, "sleep 9");
my $time_spend = time - $s;
ok($time_spend < 5, "system timeout killed");
ok($r != 0, "system timeout exit code");

$s = time;
$r = timeout(3, "sleep 9");
$time_spend = time - $s;
ok($time_spend < 5, "timeout timeout killed");
ok($r != 0, "timeout timeout exit code");

$s = time;
$r = system(5, "perl -e 'sleep 1'");
$time_spend = time - $s;
ok($time_spend < 3, "system no timeout exec");
ok($r == 0, "system timeout exit code");

$s = time;
$r = timeout(5, "perl -e 'sleep 1'");
$time_spend = time - $s;
ok($time_spend < 3, "timeout no timeout exec");
ok($r == 0, "timeout timeout exit code");
