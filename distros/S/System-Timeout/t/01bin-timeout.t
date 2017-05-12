use Test::More tests => 4;
use File::Basename qw(dirname);
chdir(dirname(__FILE__));

my $s = time;
my $r = system("../blib/script/timeout --timeout=3 sleep 9");
my $time_spend = time - $s;
ok($time_spend < 5, "bin-timeout killed");
ok($r != 0, "bin-timeout exit code");

$s = time;
$r = system("../blib/script/timeout --timeout=9 sleep 1");
$time_spend = time - $s;
ok($time_spend < 3, "bin-timeout exec");
ok($r == 0, "bin-timeout exit code");
