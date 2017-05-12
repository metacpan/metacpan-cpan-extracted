use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    my $response;
    ok($response = $freedb->read('newage', '940a040c'));
    isa_ok($response, 'CDDB::File', 'Error, object type is unexpected');
    
    ok($response->id eq '940a040c', "Error: @{[ $response->id ]} is NOT the expected 940a040c");
    ok($response->artist eq 'Deep Forest', "Error: @{[ $response->artist ]} is NOT the expected Deep Forest");
    ok($response->title eq 'Boheme', "Error: @{[ $response->title ]} is NOT the expected Boheme");
    ok($response->length == 2566, "Error: @{[ $response->length ]} is NOT the expected 2566");
    ok($response->track_count == 12, "Error: @{[ $response->track_count ]} is NOT the expected 12");
}

done_testing;
