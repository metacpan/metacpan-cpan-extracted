use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::Syslog qw(:consts :subs);

my $pri = priorityAton(NF_SYSLOG_FACILITY_LOCAL7, NF_SYSLOG_SEVERITY_INFORMATIONAL);
ok($pri, 190);

my ($fac, $sev) = priorityNtoa(190);
ok(($fac == 23) && ($sev == 6));

($fac, $sev) = priorityNtoa(190,1);
ok(($fac eq 'local7') && ($sev eq 'Informational'));
