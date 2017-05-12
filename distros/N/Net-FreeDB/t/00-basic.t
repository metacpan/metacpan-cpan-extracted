use Test::Most;

use_ok('Net::FreeDB');

my $freedb = new_ok("Net::FreeDB");

if ($ENV{HOSTNAME}) {
    ok($freedb->hostname eq $ENV{HOSTNAME}, 'Error setting hostname');
} else {
    ok($freedb->hostname eq 'unknown', 'Error setting hostname');
}

ok($freedb->remote_host eq 'freedb.freedb.org', 'Error setting default host');

ok($freedb->remote_port == 8880, 'Error setting default port');

if ($ENV{USER}) {
    ok($freedb->user eq $ENV{USER}, 'Error setting user');
} else {
    ok($freedb->user eq 'unknown', 'Error setting default user');
}

ok($freedb->timeout == 120, 'Error setting default timeout');

ok(!$freedb->debug, 'Error: debug was set but shouldn\'t be');

done_testing;
