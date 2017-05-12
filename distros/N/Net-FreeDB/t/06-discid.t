use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $disc_id;
    ok($disc_id = $freedb->discid(12, 150, 8292, 32047, 50992, 71957, 86200, 100302, 105897, 120897, 139437, 158775, 171760, 2566));
    ok($disc_id eq '9a0a040c', "DiscID: $disc_id is NOT the expected 9a0a040c");
}

done_testing;
