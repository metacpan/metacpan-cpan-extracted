use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my @response = ();
    ok(@response = $freedb->query('940a070c', 12, 150, 8285, 32097, 51042, 71992, 86235, 100345, 105935, 120932, 139472, 158810, 171795, 2567));
    
    ok(scalar(@response) eq 1);
    eq_or_diff($response[0], {
        Category => 'newage',
        DiscID   => '940a070c',
        Artist   => 'Deep Forest',
        Album    => 'Boheme',
    });
    
    my @multiple_responses = ();
    ok(@multiple_responses = $freedb->query('860aec0b', 11, 150, 19539, 34753, 52608, 69426, 86636, 112972, 130586, 151446, 172365, 191628, 2798));
    
    ok(scalar(@multiple_responses) >= 10);
    map {
        ok($_->{Artist} eq 'Foo Fighters')
    } @multiple_responses;
}

done_testing;
