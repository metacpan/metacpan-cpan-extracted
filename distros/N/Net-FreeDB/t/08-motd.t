use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my @motd_lines = ();
    ok(@motd_lines = $freedb->motd());
    ok(scalar(@motd_lines) > 1);
}

done_testing;
