use Test::More;
use Test::LWP::UserAgent;
use Test::Deep;
use Net::HTTP::Knork;
use Net::HTTP::Knork::Response;
use FindBin qw($Bin);
use JSON::MaybeXS;
my $tua = Test::LWP::UserAgent->new;

$tua->map_response(
    sub {
        my $req = shift;
        if ( $req->method eq 'POST' ) {
            my $uri_path = $req->uri->path;
            if ( $uri_path eq '/add' ) {
                my $content = decode_json( $req->content );
                return eq_deeply(
                    $content,
                    { titi => 'toto', tutu => 'plop' }
                );
            }
        }
    },
    Net::HTTP::Knork::Response->new(
        '200', 'OK',
        HTTP::Headers->new( 'Content-Type' => 'application/json' ),
        encode_json( { msg => 'resp is ok' } )
    )
);

my $client = Net::HTTP::Knork->new(
    spore_rx => "$Bin/../share/config/specs/spore_validation.rx",
    spec     => 't/fixtures/api.json',
    client   => $tua,
    encoding  => sub { 
        my $req = shift; 
            $req->content( encode_json( $req->content ) );
            $req->header( 'Content-Type' => 'application/json' );
            return $req;
        },
    decoding => sub { 
            my $resp = shift;
            $resp->content( decode_json( $resp->content ) );
            return $resp;
    }
);



$resp =
  $client->add_user(  'titi' => 'toto', 'tutu' => 'plop'  );
is( $resp->code, '200', 'request was correctly encoded' );
cmp_deeply( $resp->content, { msg => 'resp is ok' }, 'resp was correctly decoded' );
done_testing();
