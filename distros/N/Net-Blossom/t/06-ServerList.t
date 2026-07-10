use strictures 2;

use Test::More;

use Net::Blossom::ServerList;
use Net::Nostr::Event;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

my $PUBKEY = '781208004e09102d7da3b7345e64fd193cd1bc3fce8fdae6008d77f9cabcd036';
my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub bud03_event {
    return Net::Nostr::Event->new(
        id         => 'e4bee088334cb5d38cff1616e964369c37b6081be997962ab289d6c671975d71',
        pubkey     => $PUBKEY,
        content    => '',
        kind       => 10063,
        created_at => 1708774162,
        tags       => [
            ['server', 'https://cdn.self.hosted'],
            ['server', 'https://cdn.satellite.earth'],
        ],
        sig        => 'cc5efa74f59e80622c77cacf4dd62076bcb7581b45e9acff471e7963a1f4d8b3406adab5ee1ac9673487480e57d20e523428e60ffcc7e7a904ac882cfccfc653',
    );
}

subtest 'parses BUD-03 kind 10063 server list event' => sub {
    my $list = Net::Blossom::ServerList->from_event(bud03_event());

    isa_ok($list, 'Net::Blossom::ServerList');
    is_deeply(
        $list->servers,
        ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
        'server tag order is preserved',
    );
    is($list->primary_server, 'https://cdn.self.hosted', 'first server is primary');
};

subtest 'servers returns a copy array reference in scalar context' => sub {
    my $list = Net::Blossom::ServerList->new(
        servers => ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
    );

    my $servers = $list->servers;
    is(ref($servers), 'ARRAY', 'servers returns array reference');
    is_deeply($servers, ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
        'server URLs returned');

    push @$servers, 'https://mutated.example.com';
    is_deeply($list->servers, ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
        'mutating returned arrayref does not mutate object');
};

subtest 'builds ordered BUD-03 server list event' => sub {
    my $list = Net::Blossom::ServerList->new(
        servers => ['https://cdn.self.hosted', 'https://cdn.satellite.earth'],
    );

    is_deeply(
        $list->to_tags,
        [
            ['server', 'https://cdn.self.hosted'],
            ['server', 'https://cdn.satellite.earth'],
        ],
        'to_tags emits ordered server tags',
    );

    my $event = $list->to_event(pubkey => $PUBKEY, created_at => 1708774162);
    is($event->kind, 10063, 'event kind');
    is($event->content, '', 'content is empty');
    is_deeply($event->tags, $list->to_tags, 'event tags');
};

subtest 'validates BUD-03 server list inputs' => sub {
    like(dies { Net::Blossom::ServerList->new },
        qr/servers is required/, 'servers required');
    like(dies { Net::Blossom::ServerList->new(servers => 'https://cdn.example.com') },
        qr/servers must be an array reference/, 'servers arrayref required');
    like(dies { Net::Blossom::ServerList->new(servers => []) },
        qr/at least one server/, 'at least one server required');
    like(dies { Net::Blossom::ServerList->new(servers => ['cdn.example.com']) },
        qr/server url must use http or https/, 'scheme required');
    like(dies { Net::Blossom::ServerList->new(servers => ['ftp://cdn.example.com']) },
        qr/server url must use http or https/, 'non-http scheme rejected');
    like(dies { Net::Blossom::ServerList->new(servers => ['https://cdn.example.com?bad=1']) },
        qr/server url must not include a query/, 'query rejected');

    like(dies {
        Net::Blossom::ServerList->from_event({
            kind => 10063,
            tags => [['server', 'https://cdn.example.com']],
        });
    }, qr/Net::Nostr::Event/, 'plain hash events are rejected');

    my $event = bud03_event();
    $event->{kind} = 1;
    like(dies { Net::Blossom::ServerList->from_event($event) },
        qr/kind 10063/, 'wrong kind rejected');

    $event = bud03_event();
    $event->{kind} = '10063x';
    like(dies { Net::Blossom::ServerList->from_event($event) },
        qr/kind 10063/, 'malformed kind rejected');

    $event = bud03_event();
    $event->{tags} = [];
    like(dies { Net::Blossom::ServerList->from_event($event) },
        qr/at least one server/, 'missing server tag rejected');

    $event = bud03_event();
    $event->{tags} = [['server']];
    like(dies { Net::Blossom::ServerList->from_event($event) },
        qr/server tag requires a URL/, 'server tag value required');
};

subtest 'extracts the last 64-char hex hash from URLs' => sub {
    my $author = 'ec4425ff5e9446080d2f70440188e3ca5d6da8713db7bdeef73d0ed54d9093f0';

    for my $url (
        "https://blossom.example.com/$HASH.pdf",
        "https://cdn.example.com/$HASH",
        "https://cdn.example.com/user/$author/media/$HASH.pdf",
        "https://cdn.example.com/media/user-name/documents/$HASH.pdf",
        "http://download.example.com/downloads/$HASH",
        "http://media.example.com/documents/b1/67/$HASH.pdf",
    ) {
        is(Net::Blossom::ServerList->extract_sha256($url), $HASH, "hash from $url");
    }

    is(Net::Blossom::ServerList->extract_sha256("https://cdn.example.com/$author/$HASH.pdf"),
        $HASH, 'last hash wins when URL contains multiple 64-char hex strings');
    is(Net::Blossom::ServerList->extract_sha256("https://cdn.example.com/" . uc($HASH) . '.pdf'),
        $HASH, 'uppercase URL hash is normalized to lowercase');
    is(Net::Blossom::ServerList->extract_sha256('https://cdn.example.com/no-hash'),
        undef, 'no hash returns undef');
    is(Net::Blossom::ServerList->extract_sha256('https://cdn.example.com/' . ('a' x 65)),
        undef, 'does not extract from longer hex run');
};

subtest 'builds fallback URLs for listed servers' => sub {
    my $list = Net::Blossom::ServerList->new(
        servers => ['https://cdn.self.hosted/', 'https://cdn.satellite.earth'],
    );

    is_deeply(
        $list->blob_urls_for("https://broken.example.com/path/$HASH.pdf?download=1"),
        [
            "https://cdn.self.hosted/$HASH.pdf",
            "https://cdn.satellite.earth/$HASH.pdf",
        ],
        'fallback URLs preserve order and file extension',
    );
    is_deeply(
        $list->blob_urls_for("https://broken.example.com/$HASH"),
        [
            "https://cdn.self.hosted/$HASH",
            "https://cdn.satellite.earth/$HASH",
        ],
        'fallback URLs work without extension',
    );
    is_deeply($list->blob_urls_for('https://broken.example.com/no-hash'),
        [], 'no hash yields no fallback URLs');
};

done_testing;
