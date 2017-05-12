use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    ok(!$freedb->update());
    ok($freedb->error eq 'Permission denied.', "Error: actual error not the expected error");
}

done_testing;
