use strict;
use Test::More;
use Test::LWP::UserAgent;

BEGIN {
    use_ok('Rarbg::torrentapi');
}

can_ok( 'Rarbg::torrentapi',
    qw( new search list _renew_token _token_valid _make_request ) );

my $test_ua = Test::LWP::UserAgent->new;
$test_ua->map_response(
    qr{get_token},
    HTTP::Response->new(
        '200',
        HTTP::Status::status_message('200'),
        [ 'Content-Type' => 'application/json' ],
        '{"token":"8q1sjn0yb6"}',
    ),
);
$test_ua->map_response(
    qr{mode=list},
    HTTP::Response->new(
        '200', HTTP::Status::status_message('200'),
        [ 'Content-Type' => 'application/json' ],
        '{
            "torrent_results": [
                {
                    "category": "Foo Cat",
                    "download": "magnet:?xt=ublablabla",
                    "filename": "myfilename.mp4"
                },
                {
                    "category": "Bar category",
                    "download": "magnet:?xt=urn:btih:foobarbaz",
                    "filename": "blahblah.mp3"
                }
            ]
        }',
    ),
);
$test_ua->map_response(
    qr{mode=search},
    HTTP::Response->new(
        '200',
        HTTP::Status::status_message('200'),
        [ 'Content-Type' => 'application/json' ],
        '{ "error": "No results found", "error_code": 20 } ',
    ),
);
my $tapi = Rarbg::torrentapi->new( '_ua' => $test_ua );

like( $tapi->_token, qr/\w{10}/, 'Token test' );
diag( "I got token " . $tapi->_token );
ok( $tapi->_token_valid, 'Token time test' );
ok( $tapi->ranked == 0 );
is( $tapi->_format, 'json_extended' );
my $list = $tapi->list;
isa_ok( $list->[0], 'Rarbg::torrentapi::Res' );
my $res = $tapi->search(
    {
        search_string => 'qwerasdf'
    }
);
isa_ok( $res, 'Rarbg::torrentapi::Error' );

done_testing;
