use 5.014;
use FindBin qw($Bin);
use Test::Most;
use Test::JSON;
use Mojo::JSON;
use Mojo::UserAgent::Mockable::Serializer;
use Safe::Isa qw($_isa);

my $TEST_FILES_DIR = qq{$Bin/../files};

my $serializer = Mojo::UserAgent::Mockable::Serializer->new;

package TestApp {
    use Mojolicious::Lite;
    post '/target' => sub {
        my $c = shift;
        $c->render( text => 'Zip zop zoobity bop' );
    };
};
my $app = TestApp::app;
my $ua = $app->ua;
my $tx = $ua->post(
    '/target' => {
        'X-Zaphod-Last-Name'                => 'Beeblebrox',
        'X-Benedict-Cumberbatch-Silly-Name' => 'Bumbershoot Crinklypants',
        'Cookie'                            => 'foo=bar; sessionID=OU812; datingMyself=yes',
    } => form => { foo => 'bar', quux => 'quuy', thefile => { file => qq{$TEST_FILES_DIR/apocalypse_1.txt} } }
);
BAIL_OUT 'App did not respond properly' unless $tx->res->body eq 'Zip zop zoobity bop';
my %headers = %{ $tx->req->headers->to_hash };
my @assets  = map { $_->asset->slurp } @{ $tx->req->content->parts };
my $url     = $tx->req->url;

my $serialized;
lives_ok { $serialized = $serializer->serialize($tx); } q{serialize() did not die};
is_valid_json $serialized, 'serialize() emits valid JSON';
$tx = undef;
is ref Mojo::JSON::decode_json($serialized), 'ARRAY', q{Single TX serialized as an array};

lives_ok { ($tx) = $serializer->deserialize($serialized); } q{deserialize() did not die};

BAIL_OUT 'No TX' unless $tx;
BAIL_OUT 'Invalid TX' unless $tx->$_isa('Mojo::Transaction');
my $req = $tx->req;
is_deeply( $tx->req->headers->to_hash, \%headers, q{Headers match} );

is( $tx->req->url->path, $url->path, 'path match' );

is( scalar @{ $req->content->parts }, scalar @assets, q{Asset count matches} );
for ( 0 .. $#{ $req->content->parts } ) {
    my $got      = $req->content->parts->[$_]->asset->slurp;
    my $expected = $assets[$_];
    is $got, $expected, qq{Chunk $_ matches};
}

done_testing;
