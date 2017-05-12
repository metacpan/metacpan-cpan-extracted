use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    ok(!$freedb->unlink('newage', '940a040c'));
    ok($freedb->error eq 'Permission denied.', "Error: Unexpected error '@{[ $freedb->error ]}'");
}

done_testing;
