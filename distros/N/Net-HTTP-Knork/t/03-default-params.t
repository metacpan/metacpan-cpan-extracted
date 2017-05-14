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
        my $uri_path = $req->uri->path;
        if ( $req->method eq 'GET' ) {
            return ( $uri_path eq '/show/bar' );
        }
    },
    Net::HTTP::Knork::Response->new('200','OK')
);

my $client = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json',
    client   => $tua
);

$client->set_default_params({user => 'bar'});

my $resp = $client->get_user_info();
is( $resp->code, '200', 'our user is correctly set to bar' );
$client->clear_default_params(); 
dies_ok { $client->get_user_info() }  'when cleared, default parameters are not set anymore';
done_testing();
