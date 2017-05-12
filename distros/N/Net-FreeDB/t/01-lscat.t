use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my @categories = $freedb->lscat();
    eq_or_diff(sort @categories, qw/blues classical country data folk jazz misc newage reggae rock soundtrack/);
}

done_testing;
