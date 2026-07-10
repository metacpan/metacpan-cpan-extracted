use strictures 2;

use Test::More;
use JSON ();

use Net::Blossom::Client;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

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
my $SOURCE = "https://cdn.satellite.earth/$HASH.pdf";
my $JSON = JSON->new->utf8->canonical;

sub descriptor {
    return {
        url      => "https://cdn.example.com/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725105921,
    };
}

subtest 'BUD-04 PUT /mirror sends source URL JSON object' => sub {
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor()),
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $blob = $client->mirror_blob($SOURCE);
    is($blob->sha256, $HASH, 'descriptor returned');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'PUT', 'PUT method');
    is($url, 'https://cdn.example.com/mirror', 'mirror endpoint');
    is($opts->{headers}{'Content-Type'}, 'application/json', 'JSON content type');
    is($opts->{content}, $JSON->encode({ url => $SOURCE }), 'stringified JSON object body');
};

subtest 'BUD-04 PUT /mirror accepts both success statuses' => sub {
    for my $status (200, 201) {
        my $ua = Local::UA->new({
            status  => $status,
            reason  => $status == 200 ? 'OK' : 'Created',
            headers => { 'content-type' => 'application/json' },
            content => $JSON->encode(descriptor()),
        });
        my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

        is($client->mirror_blob($SOURCE)->sha256, $HASH, "$status response parsed");
    }
};

subtest 'BUD-04 upload authorization context is used for mirroring' => sub {
    my @seen;
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor()),
    });
    my $client = Net::Blossom::Client->new(
        server => 'https://cdn.example.com',
        ua     => $ua,
        auth   => sub {
            push @seen, { @_ };
            return 'Nostr token';
        },
    );

    $client->mirror_blob($SOURCE);

    is($seen[0]{action}, 'upload', 'mirror uses upload authorization');
    is($seen[0]{sha256}, $HASH, 'authorization sees mirrored blob hash');
    is(($ua->requests)[0][2]{headers}{Authorization}, 'Nostr token', 'authorization header sent');
};

subtest 'BUD-04 errors preserve X-Reason as diagnostic only' => sub {
    my $ua = Local::UA->new({
        status  => 502,
        reason  => 'Bad Gateway',
        headers => { 'x-reason' => 'origin response was unusable' },
        content => 'no',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $error = dies { $client->mirror_blob($SOURCE) };
    isa_ok($error, 'Net::Blossom::Error');
    is($error->status, 502, 'status');
    is($error->x_reason, 'origin response was unusable', 'x-reason diagnostic');
};

done_testing;
