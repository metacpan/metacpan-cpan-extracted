use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my @sites = ();
    ok(@sites = $freedb->sites());
    ok(scalar(@sites) == 1);
    
    eq_or_diff($sites[0], {
        hostname    => 'freedb.freedb.org',
        port        => 8880,
        latitude    => 'N000.00',
        longitude   => 'W000.00',
        description => 'Random freedb server',
    });
}

done_testing;
