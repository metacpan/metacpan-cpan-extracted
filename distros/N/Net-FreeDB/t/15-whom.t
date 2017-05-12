
use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    ok(!$freedb->whom());
    ok($freedb->error eq 'No user information available.', "Error: actual error not the expected error");
}

done_testing;
