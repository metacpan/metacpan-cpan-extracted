use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use NOAA::Aurora;

my $aurora = NOAA::Aurora->new();

subtest 'Wrong input' => sub {
    # get_probability checks lat/lon
    like(
        dies {$aurora->get_probability(lat => 100, lon => 0)},
        qr/lat between/,
        "Invalid lat"
    );
    like(
        dies {$aurora->get_probability(lat => 0, lon => 190)},
        qr/lon between/,
        "Invalid lon"
    );
};

my $req_cb;
my $mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    track => 1,
    override => [
        get => sub { 
            return $req_cb->(@_);
        },
    ],
);

subtest 'Error response' => sub {
    # 500 Error
    $req_cb = sub { return HTTP::Response->new(500, 'ERROR', undef, 'Server Error') };
    
    my $res;
    ok(lives { $res = $aurora->get_forecast() }, "Forecast lives on 500");
    is($res, [], "Forecast returns empty list on error/bad content");
    
    ok(lives { $res = $aurora->get_outlook() }, "Outlook lives on 500");
    is($res, [], "Outlook returns empty list on error");
    
    # get_image
    ok(lives { $res = $aurora->get_image() }, "Image lives on 500");
    like($res, qr/ERROR: 500 ERROR/, "Image returns error content");
};

done_testing;
