use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::FileMetadata;

my $PK = 'a' x 64;

###############################################################################
# Event format: kind 1063
###############################################################################

subtest 'kind 1063 event' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey  => $PK,
        content => 'A scenic photo',
        url     => 'https://example.com/photo.jpg',
        m       => 'image/jpeg',
        x       => 'abc123' . ('0' x 58),
        ox      => 'def456' . ('0' x 58),
    );
    is($event->kind, 1063, 'kind is 1063');
    is($event->content, 'A scenic photo', 'content is the caption');
};

###############################################################################
# Required tags: url, m, x, ox
###############################################################################

subtest 'required tags present in event' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey  => $PK,
        content => 'desc',
        url     => 'https://example.com/file.pdf',
        m       => 'application/pdf',
        x       => 'aa' x 32,
        ox      => 'bb' x 32,
    );
    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} = $tag;
    }
    is($tags{url}[1], 'https://example.com/file.pdf', 'url tag');
    is($tags{m}[1], 'application/pdf', 'm tag');
    is($tags{x}[1], 'aa' x 32, 'x tag (SHA-256 hex)');
    is($tags{ox}[1], 'bb' x 32, 'ox tag (SHA-256 hex)');
};

subtest 'to_event rejects missing url' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '', m => 'image/jpeg',
                x => 'aa' x 32, ox => 'bb' x 32,
            )
        },
        qr/url/i,
        'url required'
    );
};

subtest 'to_event rejects missing m' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', x => 'aa' x 32, ox => 'bb' x 32,
            )
        },
        qr/\bm\b/,
        'm required'
    );
};

subtest 'to_event rejects missing x' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg', ox => 'bb' x 32,
            )
        },
        qr/\bx\b/,
        'x required'
    );
};

subtest 'to_event rejects missing ox' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg', x => 'aa' x 32,
            )
        },
        qr/\box\b/,
        'ox required'
    );
};

###############################################################################
# Validation: x and ox must be 64-char lowercase hex (SHA-256)
###############################################################################

subtest 'x must be 64-char lowercase hex' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg',
                x => 'ZZZZ', ox => 'bb' x 32,
            )
        },
        qr/x.*hex/i,
        'x rejects non-hex'
    );
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg',
                x => 'aa' x 16, ox => 'bb' x 32,
            )
        },
        qr/x.*hex/i,
        'x rejects wrong length'
    );
};

subtest 'ox must be 64-char lowercase hex' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg',
                x => 'aa' x 32, ox => 'NOT_HEX!',
            )
        },
        qr/ox.*hex/i,
        'ox rejects non-hex'
    );
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg',
                x => 'aa' x 32, ox => 'bb' x 16,
            )
        },
        qr/ox.*hex/i,
        'ox rejects wrong length'
    );
};

###############################################################################
# Validation: m must be lowercase MIME type
###############################################################################

subtest 'm must contain a slash (MIME format)' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'jpeg',
                x => 'aa' x 32, ox => 'bb' x 32,
            )
        },
        qr/MIME/i,
        'm without slash rejected'
    );
};

subtest 'm must be lowercase' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'Image/JPEG',
                x => 'aa' x 32, ox => 'bb' x 32,
            )
        },
        qr/lowercase/i,
        'm with uppercase rejected'
    );
};

###############################################################################
# Optional tags
###############################################################################

subtest 'optional tags: size' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        size => '1048576',
    );
    my ($tag) = grep { $_->[0] eq 'size' } @{$event->tags};
    is($tag->[1], '1048576', 'size tag present');
};

subtest 'optional tags: dim' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        dim => '1920x1080',
    );
    my ($tag) = grep { $_->[0] eq 'dim' } @{$event->tags};
    is($tag->[1], '1920x1080', 'dim tag present');
};

subtest 'optional tags: magnet' => sub {
    my $uri = 'magnet:?xt=urn:btih:abc123';
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        magnet => $uri,
    );
    my ($tag) = grep { $_->[0] eq 'magnet' } @{$event->tags};
    is($tag->[1], $uri, 'magnet tag present');
};

subtest 'optional tags: i (torrent infohash)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        i => 'abc123def456',
    );
    my ($tag) = grep { $_->[0] eq 'i' } @{$event->tags};
    is($tag->[1], 'abc123def456', 'i tag present');
};

subtest 'optional tags: blurhash' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        blurhash => 'eVF$^OI:Vs',
    );
    my ($tag) = grep { $_->[0] eq 'blurhash' } @{$event->tags};
    is($tag->[1], 'eVF$^OI:Vs', 'blurhash tag present');
};

subtest 'optional tags: summary' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'application/pdf',
        x => 'aa' x 32, ox => 'bb' x 32,
        summary => 'Chapter 1 excerpt',
    );
    my ($tag) = grep { $_->[0] eq 'summary' } @{$event->tags};
    is($tag->[1], 'Chapter 1 excerpt', 'summary tag present');
};

subtest 'optional tags: alt' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        alt => 'A photo of a sunset',
    );
    my ($tag) = grep { $_->[0] eq 'alt' } @{$event->tags};
    is($tag->[1], 'A photo of a sunset', 'alt tag present');
};

subtest 'optional tags: service' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        service => 'nip96',
    );
    my ($tag) = grep { $_->[0] eq 'service' } @{$event->tags};
    is($tag->[1], 'nip96', 'service tag present');
};

###############################################################################
# Optional tags: thumb and image (with optional SHA-256 hash)
###############################################################################

subtest 'optional tags: thumb (URL only)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        thumb => 'https://example.com/thumb.jpg',
    );
    my ($tag) = grep { $_->[0] eq 'thumb' } @{$event->tags};
    is($tag->[1], 'https://example.com/thumb.jpg', 'thumb URL');
    is(scalar @$tag, 2, 'no hash element when not provided');
};

subtest 'optional tags: thumb (URL + hash)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        thumb      => 'https://example.com/thumb.jpg',
        thumb_hash => 'cc' x 32,
    );
    my ($tag) = grep { $_->[0] eq 'thumb' } @{$event->tags};
    is($tag->[1], 'https://example.com/thumb.jpg', 'thumb URL');
    is($tag->[2], 'cc' x 32, 'thumb hash');
};

subtest 'optional tags: image (URL only)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        image => 'https://example.com/preview.jpg',
    );
    my ($tag) = grep { $_->[0] eq 'image' } @{$event->tags};
    is($tag->[1], 'https://example.com/preview.jpg', 'image URL');
    is(scalar @$tag, 2, 'no hash element when not provided');
};

subtest 'optional tags: image (URL + hash)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        image      => 'https://example.com/preview.jpg',
        image_hash => 'dd' x 32,
    );
    my ($tag) = grep { $_->[0] eq 'image' } @{$event->tags};
    is($tag->[1], 'https://example.com/preview.jpg', 'image URL');
    is($tag->[2], 'dd' x 32, 'image hash');
};

###############################################################################
# Optional tags: fallback (zero or more)
###############################################################################

subtest 'optional tags: fallback (multiple)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
        fallback => [
            'https://alt1.example.com/f',
            'https://alt2.example.com/f',
        ],
    );
    my @fb = grep { $_->[0] eq 'fallback' } @{$event->tags};
    is(scalar @fb, 2, 'two fallback tags');
    is($fb[0][1], 'https://alt1.example.com/f', 'first fallback');
    is($fb[1][1], 'https://alt2.example.com/f', 'second fallback');
};

subtest 'optional tags: no fallback by default' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
    );
    my @fb = grep { $_->[0] eq 'fallback' } @{$event->tags};
    is(scalar @fb, 0, 'no fallback tags when not provided');
};

###############################################################################
# Spec JSON example
###############################################################################

subtest 'spec JSON example' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey   => $PK,
        content  => '<caption>',
        url      => 'https://example.com/file.jpg',
        m        => 'image/jpeg',
        x        => 'aa' x 32,
        ox       => 'bb' x 32,
        size     => '123456',
        dim      => '800x600',
        magnet   => 'magnet:?xt=urn:btih:abc',
        i        => 'abc123',
        blurhash => 'eVF$^OI',
        thumb      => 'https://example.com/thumb.jpg',
        thumb_hash => 'cc' x 32,
        image      => 'https://example.com/preview.jpg',
        image_hash => 'dd' x 32,
        summary  => 'excerpt text',
        alt      => 'description text',
    );
    is($event->kind, 1063, 'kind 1063');
    is($event->content, '<caption>', 'content is caption');

    my %tags;
    for my $tag (@{$event->tags}) {
        push @{$tags{$tag->[0]}}, $tag;
    }
    ok($tags{url}, 'has url');
    ok($tags{m}, 'has m');
    ok($tags{x}, 'has x');
    ok($tags{ox}, 'has ox');
    ok($tags{size}, 'has size');
    ok($tags{dim}, 'has dim');
    ok($tags{magnet}, 'has magnet');
    ok($tags{i}, 'has i');
    ok($tags{blurhash}, 'has blurhash');
    ok($tags{thumb}, 'has thumb');
    ok($tags{image}, 'has image');
    ok($tags{summary}, 'has summary');
    ok($tags{alt}, 'has alt');
};

###############################################################################
# from_event: parse kind 1063 event back to FileMetadata
###############################################################################

subtest 'from_event: round-trip' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey     => $PK,
        content    => 'A photo',
        url        => 'https://example.com/photo.jpg',
        m          => 'image/jpeg',
        x          => 'aa' x 32,
        ox         => 'bb' x 32,
        size       => '1048576',
        dim        => '1920x1080',
        magnet     => 'magnet:?xt=urn:btih:abc123',
        i          => 'deadbeef',
        blurhash   => 'eVF$^OI',
        thumb      => 'https://example.com/thumb.jpg',
        thumb_hash => 'cc' x 32,
        image      => 'https://example.com/preview.jpg',
        image_hash => 'dd' x 32,
        summary    => 'excerpt',
        alt        => 'scenic photo',
        fallback   => ['https://alt.example.com/photo.jpg'],
        service    => 'nip96',
    );

    my $fm = Net::Nostr::FileMetadata->from_event($event);
    ok($fm, 'from_event returns an object');
    is($fm->url, 'https://example.com/photo.jpg', 'url');
    is($fm->m, 'image/jpeg', 'm');
    is($fm->x, 'aa' x 32, 'x');
    is($fm->ox, 'bb' x 32, 'ox');
    is($fm->size, '1048576', 'size');
    is($fm->dim, '1920x1080', 'dim');
    is($fm->magnet, 'magnet:?xt=urn:btih:abc123', 'magnet');
    is($fm->i, 'deadbeef', 'i');
    is($fm->blurhash, 'eVF$^OI', 'blurhash');
    is($fm->thumb, 'https://example.com/thumb.jpg', 'thumb');
    is($fm->thumb_hash, 'cc' x 32, 'thumb_hash');
    is($fm->image, 'https://example.com/preview.jpg', 'image');
    is($fm->image_hash, 'dd' x 32, 'image_hash');
    is($fm->summary, 'excerpt', 'summary');
    is($fm->alt, 'scenic photo', 'alt');
    is($fm->fallback, ['https://alt.example.com/photo.jpg'], 'fallback');
    is($fm->service, 'nip96', 'service');
};

subtest 'from_event: returns undef for non-1063 kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => 'hello', tags => [],
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm, undef, 'returns undef for kind 1');
};

subtest 'from_event: minimal (required tags only)' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/png',
        x => 'aa' x 32, ox => 'bb' x 32,
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm->url, 'https://example.com/f', 'url');
    is($fm->m, 'image/png', 'm');
    is($fm->x, 'aa' x 32, 'x');
    is($fm->ox, 'bb' x 32, 'ox');
    is($fm->size, undef, 'size is undef');
    is($fm->dim, undef, 'dim is undef');
    is($fm->thumb, undef, 'thumb is undef');
    is($fm->fallback, [], 'fallback is empty');
};

###############################################################################
# from_event: thumb and image with optional hashes
###############################################################################

subtest 'from_event: thumb without hash' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
            ['thumb', 'https://example.com/thumb.jpg'],
        ],
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm->thumb, 'https://example.com/thumb.jpg', 'thumb URL');
    is($fm->thumb_hash, undef, 'no thumb hash');
};

subtest 'from_event: image with hash' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
            ['image', 'https://example.com/preview.jpg', 'dd' x 32],
        ],
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is($fm->image, 'https://example.com/preview.jpg', 'image URL');
    is($fm->image_hash, 'dd' x 32, 'image hash');
};

###############################################################################
# from_event: multiple fallback tags
###############################################################################

subtest 'from_event: multiple fallback tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
            ['fallback', 'https://alt1.example.com/f'],
            ['fallback', 'https://alt2.example.com/f'],
        ],
    );
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    is(
        $fm->fallback,
        ['https://alt1.example.com/f', 'https://alt2.example.com/f'],
        'multiple fallback URLs'
    );
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid event' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
    );
    ok(Net::Nostr::FileMetadata->validate($event), 'valid event passes');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
        ],
    );
    like(
        dies { Net::Nostr::FileMetadata->validate($event) },
        qr/kind.*1063/i,
        'rejects wrong kind'
    );
};

subtest 'validate: missing url tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
        ],
    );
    like(
        dies { Net::Nostr::FileMetadata->validate($event) },
        qr/url/,
        'rejects missing url'
    );
};

subtest 'validate: missing m tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['x', 'aa' x 32],
            ['ox', 'bb' x 32],
        ],
    );
    like(
        dies { Net::Nostr::FileMetadata->validate($event) },
        qr/\bm\b/,
        'rejects missing m'
    );
};

subtest 'validate: missing x tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['ox', 'bb' x 32],
        ],
    );
    like(
        dies { Net::Nostr::FileMetadata->validate($event) },
        qr/\bx\b/,
        'rejects missing x'
    );
};

subtest 'validate: missing ox tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1063, content => '',
        tags => [
            ['url', 'https://example.com/f'],
            ['m', 'image/jpeg'],
            ['x', 'aa' x 32],
        ],
    );
    like(
        dies { Net::Nostr::FileMetadata->validate($event) },
        qr/\box\b/,
        'rejects missing ox'
    );
};

###############################################################################
# to_event passes through extra Event args (created_at, tags)
###############################################################################

subtest 'to_event: passes created_at' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey     => $PK,
        content    => '',
        created_at => 1700000000,
        url        => 'https://example.com/f',
        m          => 'image/jpeg',
        x          => 'aa' x 32,
        ox         => 'bb' x 32,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

subtest 'to_event: preserves additional tags' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url    => 'https://example.com/f', m => 'image/jpeg',
        x      => 'aa' x 32, ox => 'bb' x 32,
        extra_tags => [['t', 'photo'], ['e', 'ff' x 32]],
    );
    my @t_tags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @t_tags, 1, 'extra t tag present');
    is($t_tags[0][1], 'photo', 't tag value');
};

###############################################################################
# to_event: all optional tags at once
###############################################################################

subtest 'to_event: all fields' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey     => $PK,
        content    => 'full example',
        url        => 'https://example.com/file.pdf',
        m          => 'application/pdf',
        x          => 'aa' x 32,
        ox         => 'bb' x 32,
        size       => '999',
        dim        => '800x600',
        magnet     => 'magnet:?xt=urn:btih:abc',
        i          => 'infohash123',
        blurhash   => 'LGF5]+Yk',
        thumb      => 'https://example.com/thumb.png',
        thumb_hash => 'cc' x 32,
        image      => 'https://example.com/preview.png',
        image_hash => 'dd' x 32,
        summary    => 'an excerpt',
        alt        => 'accessibility text',
        fallback   => ['https://alt.example.com/file.pdf'],
        service    => 'nip96',
    );

    my %tags;
    for my $tag (@{$event->tags}) {
        push @{$tags{$tag->[0]}}, $tag;
    }

    is($tags{url}[0][1], 'https://example.com/file.pdf');
    is($tags{m}[0][1], 'application/pdf');
    is($tags{x}[0][1], 'aa' x 32);
    is($tags{ox}[0][1], 'bb' x 32);
    is($tags{size}[0][1], '999');
    is($tags{dim}[0][1], '800x600');
    is($tags{magnet}[0][1], 'magnet:?xt=urn:btih:abc');
    is($tags{i}[0][1], 'infohash123');
    is($tags{blurhash}[0][1], 'LGF5]+Yk');
    is($tags{thumb}[0][1], 'https://example.com/thumb.png');
    is($tags{thumb}[0][2], 'cc' x 32);
    is($tags{image}[0][1], 'https://example.com/preview.png');
    is($tags{image}[0][2], 'dd' x 32);
    is($tags{summary}[0][1], 'an excerpt');
    is($tags{alt}[0][1], 'accessibility text');
    is($tags{fallback}[0][1], 'https://alt.example.com/file.pdf');
    is($tags{service}[0][1], 'nip96');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::FileMetadata->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

subtest 'constructor: all accessors' => sub {
    my $fm = Net::Nostr::FileMetadata->new(
        url        => 'https://example.com/f',
        m          => 'image/jpeg',
        x          => 'aa' x 32,
        ox         => 'bb' x 32,
        size       => '999',
        dim        => '800x600',
        magnet     => 'magnet:?xt=urn:btih:abc',
        i          => 'hash',
        blurhash   => 'abc',
        thumb      => 'https://example.com/thumb.jpg',
        thumb_hash => 'cc' x 32,
        image      => 'https://example.com/preview.jpg',
        image_hash => 'dd' x 32,
        summary    => 'excerpt',
        alt        => 'description',
        fallback   => ['https://alt.example.com/f'],
        service    => 'nip96',
    );
    is($fm->url, 'https://example.com/f');
    is($fm->m, 'image/jpeg');
    is($fm->size, '999');
    is($fm->fallback, ['https://alt.example.com/f']);
};

###############################################################################
# dim validation
###############################################################################

subtest 'dim must be WxH format' => sub {
    like(
        dies {
            Net::Nostr::FileMetadata->to_event(
                pubkey => $PK, content => '',
                url => 'https://example.com/f', m => 'image/jpeg',
                x => 'aa' x 32, ox => 'bb' x 32,
                dim => 'large',
            )
        },
        qr/dim/i,
        'dim rejects non-WxH'
    );
};

###############################################################################
# kind 1063 is regular (not replaceable, not ephemeral, not addressable)
###############################################################################

subtest 'kind 1063 is regular' => sub {
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey => $PK, content => '',
        url => 'https://example.com/f', m => 'image/jpeg',
        x => 'aa' x 32, ox => 'bb' x 32,
    );
    ok($event->is_regular, 'kind 1063 is regular');
    ok(!$event->is_replaceable, 'not replaceable');
    ok(!$event->is_ephemeral, 'not ephemeral');
    ok(!$event->is_addressable, 'not addressable');
};

done_testing;
