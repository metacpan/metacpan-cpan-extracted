use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
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
my $JSON = JSON->new->utf8->canonical;

sub descriptor {
    return {
        url      => "https://cdn.example.com/$HASH.webp",
        sha256   => $HASH,
        size     => 81337,
        type     => 'image/webp',
        uploaded => 1725105921,
    };
}

subtest 'BUD-05 PUT /media accepts binary media and sends body metadata' => sub {
    my $body = pack('C*', 0, 255, 137, 80, 78, 71, 10);
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor()),
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $blob = $client->process_media($body, type => 'image/png');
    is($blob->sha256, $HASH, 'optimized descriptor returned');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'PUT', 'PUT method');
    is($url, 'https://cdn.example.com/media', 'media endpoint');
    is($opts->{content}, $body, 'exact binary body sent');
    is($opts->{headers}{'Content-Type'}, 'image/png', 'content type header');
    is($opts->{headers}{'Content-Length'}, length($body), 'content length header');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($body), 'body hash header');
};

subtest 'BUD-05 PUT /media accepts both success statuses' => sub {
    for my $status (200, 201) {
        my $ua = Local::UA->new({
            status  => $status,
            reason  => $status == 200 ? 'OK' : 'Created',
            headers => { 'content-type' => 'application/json' },
            content => $JSON->encode(descriptor()),
        });
        my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

        is($client->process_media('media bytes')->sha256, $HASH, "$status response parsed");
    }
};

subtest 'BUD-05 HEAD /media sends preflight headers and no body' => sub {
    my $body = 'short video bytes';
    my $ua = Local::UA->new({
        status  => 200,
        reason  => 'OK',
        headers => { 'x-reason' => 'accepted' },
        content => '',
    });
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $ua);

    my $response = $client->head_media($body, type => 'video/mp4');
    is($response->status, 200, 'preflight accepted');
    is($response->header('x-reason'), 'accepted', 'diagnostic header available');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'HEAD', 'HEAD method');
    is($url, 'https://cdn.example.com/media', 'media endpoint');
    ok(!exists $opts->{content}, 'HEAD request has no body');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($body), 'body hash preflight header');
    is($opts->{headers}{'X-Content-Type'}, 'video/mp4', 'content type preflight header');
    is($opts->{headers}{'X-Content-Length'}, length($body), 'content length preflight header');
};

subtest 'BUD-05 media endpoints use media authorization context' => sub {
    my @seen;
    my $body = 'authorized media';
    my $ua = Local::UA->new(
        {
            status  => 200,
            reason  => 'OK',
            headers => {},
            content => '',
        },
        {
            status  => 201,
            reason  => 'Created',
            headers => { 'content-type' => 'application/json' },
            content => $JSON->encode(descriptor()),
        },
    );
    my $client = Net::Blossom::Client->new(
        server => 'https://cdn.example.com',
        ua     => $ua,
        auth   => sub {
            push @seen, { @_ };
            return 'Nostr media-token';
        },
    );

    $client->head_media($body);
    $client->process_media($body);

    is($seen[0]{method}, 'HEAD', 'HEAD auth method');
    is($seen[0]{url}, 'https://cdn.example.com/media', 'HEAD auth URL');
    is($seen[0]{action}, 'media', 'HEAD auth action');
    is($seen[0]{sha256}, sha256_hex($body), 'HEAD auth hash');
    is($seen[1]{method}, 'PUT', 'PUT auth method');
    is($seen[1]{url}, 'https://cdn.example.com/media', 'PUT auth URL');
    is($seen[1]{action}, 'media', 'PUT auth action');
    is($seen[1]{sha256}, sha256_hex($body), 'PUT auth hash');

    my @requests = $ua->requests;
    is($requests[0][2]{headers}{Authorization}, 'Nostr media-token', 'HEAD authorization header sent');
    is($requests[1][2]{headers}{Authorization}, 'Nostr media-token', 'PUT authorization header sent');
};

subtest 'BUD-05 rejection statuses preserve X-Reason diagnostics' => sub {
    my $put_ua = Local::UA->new({
        status  => 422,
        reason  => 'Unprocessable Content',
        headers => { 'x-reason' => 'could not decode image' },
        content => 'no',
    });
    my $put_client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $put_ua);

    my $put_error = dies { $put_client->process_media('bad image') };
    isa_ok($put_error, 'Net::Blossom::Error');
    is($put_error->status, 422, 'PUT status');
    is($put_error->x_reason, 'could not decode image', 'PUT x-reason diagnostic');

    my $head_ua = Local::UA->new({
        status  => 413,
        reason  => 'Content Too Large',
        headers => { 'x-reason' => 'maximum media size is 10MB' },
        content => '',
    });
    my $head_client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => $head_ua);

    my $head_error = dies { $head_client->head_media('large image') };
    isa_ok($head_error, 'Net::Blossom::Error');
    is($head_error->status, 413, 'HEAD status');
    is($head_error->x_reason, 'maximum media size is 10MB', 'HEAD x-reason diagnostic');
};

subtest 'BUD-05 media content is required' => sub {
    my $client = Net::Blossom::Client->new(server => 'https://cdn.example.com', ua => Local::UA->new);

    like(dies { $client->process_media() },
        qr/content is required/, 'PUT media requires content');
    like(dies { $client->head_media() },
        qr/content is required/, 'HEAD media requires content');
};

done_testing;
