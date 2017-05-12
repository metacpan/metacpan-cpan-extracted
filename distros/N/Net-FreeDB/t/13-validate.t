use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    ok(!$freedb->validate("salt=12345"));
    ok($freedb->error eq 'Validation not required.', "Error: actual error not the expected error");
}

done_testing;
