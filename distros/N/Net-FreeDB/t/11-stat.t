use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $server_stats;
    ok($server_stats = $freedb->stat());
    
    ok($server_stats->{"current proto"} == 1);
    ok($server_stats->{"max proto"} == 6);
    ok($server_stats->{interface} eq 'cddbp');
    ok($server_stats->{gets} eq 'no');
    ok($server_stats->{puts} eq 'no');
    ok($server_stats->{updates} eq 'no');
    ok($server_stats->{posting} eq 'no');
    ok($server_stats->{validation} eq 'accepted');
    ok($server_stats->{quotes} eq 'no');
    ok($server_stats->{"strip ext"} eq 'no');
    ok($server_stats->{secure} eq 'yes');
}

done_testing;
