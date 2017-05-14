use Test::More;
use Test::LWP::UserAgent;
use Test::Deep;
use Test::Exception;
use Net::HTTP::Knork;
use Net::HTTP::Knork::Response;
use FindBin qw($Bin);

my $tua = Test::LWP::UserAgent->new;

$tua->map_response(
    sub {
        my $req = shift;
        my $uri = $req->uri->as_string;
        if ( $req->method eq 'GET' ) {
            return ( $uri eq 'http://otherhost.localdomain/other_domain'),
        }
    },
    Net::HTTP::Knork::Response->new('200','OK')
);

my $client = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json',
    client   => $tua
);
my $resp = $client->get_other_domain();
is( $resp->code, '200', 'the base url is changed correctly' );

done_testing();
