use Test;
BEGIN { plan(tests => 2) }

use Net::Frame::Layer::NTP qw(:consts :subs);

my $ret = ntp2date(3661791512,956853259);
#ok($ret eq "Jan 14 2016 20:18:32.222784760175273 UTC");
ok(substr ($ret, 0, 30) eq "Jan 14 2016 20:18:32.222784760");

$ret = ntpTimestamp(3661791512);
ok($ret, 5870780312);
