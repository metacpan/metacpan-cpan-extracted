use strictures 2;

use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON ();

use Net::Blossom::Client;
use Net::Blossom::ServerList;
use Net::Nostr::Event;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::UA;
    use strictures 2;

    sub new {
        my ($class, @responses) = @_;
        return bless { responses => \@responses, requests => [] }, $class;
    }

    sub request {
        my ($self, $method, $url, $opts) = @_;
        push @{$self->{requests}}, [$method, $url, $opts || {}];
        return shift @{$self->{responses}};
    }

    sub requests {
        my ($self) = @_;
        return @{$self->{requests}};
    }
}

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';
my $AUTHOR = 'ec4425ff5e9446080d2f70440188e3ca5d6da8713db7bdeef73d0ed54d9093f0';
my $JSON = JSON->new->utf8->canonical;

sub descriptor_hash {
    return {
        url      => "https://cdn.self.hosted/$HASH.pdf",
        sha256   => $HASH,
        size     => 184292,
        type     => 'application/pdf',
        uploaded => 1725105921,
    };
}

sub server_list {
    return Net::Blossom::ServerList->new(
        servers => ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
    );
}

subtest 'BUD-03 user server list preserves trusted server order' => sub {
    my $list = Net::Blossom::ServerList->from_event(Net::Nostr::Event->new(
        pubkey  => $AUTHOR,
        kind    => 10063,
        content => '',
        tags    => [
            ['server', 'https://cdn.self.hosted'],
            ['server', 'https://cdn.satellite.earth'],
        ],
    ));

    is_deeply(
        $list->servers,
        ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
        'server order preserved',
    );
};

subtest 'BUD-03 upload attempts at least the first listed server' => sub {
    my $body = 'BUD-03 upload';
    my $ua = Local::UA->new({
        status  => 201,
        reason  => 'Created',
        headers => { 'content-type' => 'application/json' },
        content => $JSON->encode(descriptor_hash()),
    });
    my $client = Net::Blossom::Client->new(
        server => 'https://unused.example.com',
        ua     => $ua,
    );

    my $descriptor = $client->upload_blob_to_servers($body, server_list(), type => 'text/plain');
    is($descriptor->sha256, $HASH, 'descriptor parsed');

    my ($method, $url, $opts) = @{($ua->requests)[0]};
    is($method, 'PUT', 'PUT upload');
    is($url, 'https://cdn.self.hosted/upload', 'first listed server used');
    is($opts->{headers}{'X-SHA-256'}, sha256_hex($body), 'sha256 advisory header');
};

subtest 'BUD-03 clients extract the last 64-char hex string from URLs' => sub {
    for my $url (
        "https://blossom.example.com/$HASH.pdf",
        "https://cdn.example.com/$HASH",
        "https://cdn.example.com/user/$AUTHOR/media/$HASH.pdf",
        "https://cdn.example.com/media/user-name/documents/$HASH.pdf",
        "http://download.example.com/downloads/$HASH",
        "http://media.example.com/documents/b1/67/$HASH.pdf",
    ) {
        is(Net::Blossom::ServerList->extract_sha256($url), $HASH, "hash from $url");
    }
};

subtest 'BUD-03 retrieval tries user servers in listed order' => sub {
    my $ua = Local::UA->new(
        {
            status  => 404,
            reason  => 'Not Found',
            headers => { 'x-reason' => 'missing' },
            content => '',
        },
        {
            status  => 200,
            reason  => 'OK',
            headers => { 'content-type' => 'application/pdf' },
            content => 'blob',
        },
    );
    my $client = Net::Blossom::Client->new(
        server => 'https://unused.example.com',
        ua     => $ua,
    );

    my $response = $client->get_blob_from_servers(
        "https://cdn.broken-domain.com/$HASH.pdf",
        server_list(),
    );

    is($response->status, 200, 'second server response returned');
    my @requests = $ua->requests;
    is($requests[0][1], "https://cdn.self.hosted/$HASH.pdf", 'first server attempted first');
    is($requests[1][1], "https://cdn.satellite.earth/$HASH.pdf", 'second server attempted after first miss');
};

subtest 'BUD-03 retrieval validates URL hash extraction' => sub {
    my $client = Net::Blossom::Client->new(server => 'https://unused.example.com', ua => Local::UA->new);
    like(dies { $client->get_blob_from_servers('https://cdn.example.com/no-hash', server_list()) },
        qr/URL does not contain a sha256 hash/, 'missing hash rejected');
};

done_testing;
