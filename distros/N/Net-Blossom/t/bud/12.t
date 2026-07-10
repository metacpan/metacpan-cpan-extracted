use strictures 2;

use Test::More;
use JSON ();

use Net::Blossom::Client;

{
    package Local::UA;
    use strictures 2;
    sub new { bless { requests => [], responses => [@_[1 .. $#_]] }, $_[0] }
    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{$self->{requests}}, [$method, $url, $opts || {}];
        return shift @{$self->{responses}};
    }
    sub requests { @{$_[0]->{requests}} }
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $JSON = JSON->new->utf8->canonical;

sub descriptor {
    return {
        url => "https://cdn.example.com/$HASH.pdf",
        sha256 => $HASH,
        size => 184292,
        type => 'application/pdf',
        uploaded => 1725105921,
    };
}

subtest 'BUD-12 GET /list/<pubkey> supports cursor pagination params' => sub {
    my $ua = Local::UA->new({ status => 200, reason => 'OK', headers => {}, content => $JSON->encode([descriptor()]) });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
    my $blobs = $client->list_blobs($PUBKEY, cursor => $HASH, limit => 10);
    is(ref($blobs), 'ARRAY', 'arrayref response');
    is(scalar @$blobs, 1, 'one descriptor');
    my $request = ($ua->requests)[0];
    my ($method, $url) = @$request;
    is($method, 'GET', 'GET');
    is($url, "https://cdn.example.com/list/$PUBKEY?cursor=$HASH&limit=10", 'pagination URL');
};

subtest 'BUD-12 DELETE /<sha256> accepts 200 and 204' => sub {
    for my $status (200, 204) {
        my $ua = Local::UA->new({ status => $status, reason => 'OK', headers => {}, content => '' });
        my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);
        my $response = $client->delete_blob($HASH);
        is($response->status, $status, "delete status $status");
    }
};

done_testing;
