use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::Torrent;

my $PK = 'a' x 64;

###############################################################################
# Kind 2003: Torrent event
###############################################################################

subtest 'torrent: kind 2003' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title     => 'Example Torrent',
        content   => 'A long description',
    );
    is($event->kind, 2003, 'kind is 2003');
};

###############################################################################
# Spec: x tag — V1 BitTorrent Info Hash
###############################################################################

subtest 'torrent: x tag (info hash)' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title     => 'Test',
    );
    my @x = grep { $_->[0] eq 'x' } @{$event->tags};
    is(scalar @x, 1, 'one x tag');
    is($x[0][1], 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3', 'info hash value');
};

###############################################################################
# Spec: title tag
###############################################################################

subtest 'torrent: title tag' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title     => 'Example Torrent',
    );
    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is(scalar @title, 1, 'one title tag');
    is($title[0][1], 'Example Torrent', 'title value');
};

###############################################################################
# Spec: content is long description, pre-formatted
###############################################################################

subtest 'torrent: content is description' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
        content   => "Line 1\nLine 2\nLine 3",
    );
    is($event->content, "Line 1\nLine 2\nLine 3", 'content preserved');
};

subtest 'torrent: content defaults to empty string' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
    );
    is($event->content, '', 'empty content by default');
};

###############################################################################
# Spec: file tag — full path and file size in bytes
###############################################################################

subtest 'torrent: file tags' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
        files     => [
            ['info/example.txt', '1024'],
            ['data/movie.mkv', '4294967296'],
        ],
    );
    my @files = grep { $_->[0] eq 'file' } @{$event->tags};
    is(scalar @files, 2, 'two file tags');
    is($files[0], ['file', 'info/example.txt', '1024'], 'first file');
    is($files[1], ['file', 'data/movie.mkv', '4294967296'], 'second file');
};

###############################################################################
# Spec: tracker tag (Optional)
###############################################################################

subtest 'torrent: tracker tags' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
        trackers  => [
            'udp://mytacker.com:1337',
            'http://1337-tracker.net/announce',
        ],
    );
    my @trackers = grep { $_->[0] eq 'tracker' } @{$event->tags};
    is(scalar @trackers, 2, 'two tracker tags');
    is($trackers[0][1], 'udp://mytacker.com:1337', 'first tracker');
    is($trackers[1][1], 'http://1337-tracker.net/announce', 'second tracker');
};

subtest 'torrent: no trackers (optional)' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
    );
    my @trackers = grep { $_->[0] eq 'tracker' } @{$event->tags};
    is(scalar @trackers, 0, 'no tracker tags');
};

###############################################################################
# Spec: i tags for tag prefixes (tcat, newznab, tmdb, ttvdb, imdb, mal, anilist)
###############################################################################

subtest 'torrent: i tags (tag prefixes)' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Test',
        identifiers => [
            'tcat:video,movie,4k',
            'newznab:2045',
            'imdb:tt15239678',
            'tmdb:movie:693134',
            'ttvdb:movie:290272',
        ],
    );
    my @itags = grep { $_->[0] eq 'i' } @{$event->tags};
    is(scalar @itags, 5, 'five i tags');
    is($itags[0][1], 'tcat:video,movie,4k', 'tcat');
    is($itags[1][1], 'newznab:2045', 'newznab');
    is($itags[2][1], 'imdb:tt15239678', 'imdb');
    is($itags[3][1], 'tmdb:movie:693134', 'tmdb');
    is($itags[4][1], 'ttvdb:movie:290272', 'ttvdb');
};

###############################################################################
# Spec: t tags for searchable categories (SHOULD include)
###############################################################################

subtest 'torrent: t tags (searchable hashtags)' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
        hashtags  => ['movie', '4k'],
    );
    my @ttags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @ttags, 2, 'two t tags');
    is($ttags[0][1], 'movie', 'first hashtag');
    is($ttags[1][1], '4k', 'second hashtag');
};

###############################################################################
# Spec JSON example: full torrent event
###############################################################################

subtest 'torrent: spec JSON example' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Example Torrent',
        content     => '<long-description-pre-formatted>',
        files       => [
            ['<file-name>', '<file-size-in-bytes>'],
            ['<file-name>', '<file-size-in-bytes>'],
        ],
        trackers    => [
            'udp://mytacker.com:1337',
            'http://1337-tracker.net/announce',
        ],
        identifiers => [
            'tcat:video,movie,4k',
            'newznab:2045',
            'imdb:tt15239678',
            'tmdb:movie:693134',
            'ttvdb:movie:290272',
        ],
        hashtags    => ['movie', '4k'],
    );

    is($event->kind, 2003, 'kind');
    is($event->content, '<long-description-pre-formatted>', 'content');

    my @title = grep { $_->[0] eq 'title' } @{$event->tags};
    is($title[0][1], 'Example Torrent', 'title');

    my @x = grep { $_->[0] eq 'x' } @{$event->tags};
    is($x[0][1], 'abcd1234abcd1234abcd1234abcd1234abcd1234', 'x');

    my @files = grep { $_->[0] eq 'file' } @{$event->tags};
    is(scalar @files, 2, 'file count');

    my @trackers = grep { $_->[0] eq 'tracker' } @{$event->tags};
    is(scalar @trackers, 2, 'tracker count');
    is($trackers[0][1], 'udp://mytacker.com:1337', 'tracker 1');
    is($trackers[1][1], 'http://1337-tracker.net/announce', 'tracker 2');

    my @itags = grep { $_->[0] eq 'i' } @{$event->tags};
    is(scalar @itags, 5, 'i tag count');
    is($itags[0][1], 'tcat:video,movie,4k', 'tcat');
    is($itags[1][1], 'newznab:2045', 'newznab');
    is($itags[2][1], 'imdb:tt15239678', 'imdb');
    is($itags[3][1], 'tmdb:movie:693134', 'tmdb');
    is($itags[4][1], 'ttvdb:movie:290272', 'ttvdb');

    my @ttags = grep { $_->[0] eq 't' } @{$event->tags};
    is(scalar @ttags, 2, 't tag count');
    is($ttags[0][1], 'movie', 'movie tag');
    is($ttags[1][1], '4k', '4k tag');
};

###############################################################################
# Tag prefix types: tcat, newznab, tmdb, ttvdb, imdb, mal, anilist
###############################################################################

subtest 'torrent: mal tag prefix' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Test',
        identifiers => ['mal:anime:9253'],
    );
    my @itags = grep { $_->[0] eq 'i' } @{$event->tags};
    is($itags[0][1], 'mal:anime:9253', 'mal:anime prefix');
};

subtest 'torrent: anilist tag prefix' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Test',
        identifiers => ['anilist:12345'],
    );
    my @itags = grep { $_->[0] eq 'i' } @{$event->tags};
    is($itags[0][1], 'anilist:12345', 'anilist prefix');
};

# Spec: second level prefix for databases with multiple media types
subtest 'torrent: second level prefixes' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Test',
        identifiers => [
            'tmdb:movie:693134',
            'ttvdb:movie:290272',
            'mal:anime:9253',
            'mal:manga:17517',
        ],
    );
    my @itags = grep { $_->[0] eq 'i' } @{$event->tags};
    is($itags[0][1], 'tmdb:movie:693134', 'tmdb:movie');
    is($itags[1][1], 'ttvdb:movie:290272', 'ttvdb:movie');
    is($itags[2][1], 'mal:anime:9253', 'mal:anime');
    is($itags[3][1], 'mal:manga:17517', 'mal:manga');
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: round-trip all fields' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title       => 'Test Torrent',
        content     => 'Description here',
        files       => [
            ['video.mkv', '1073741824'],
            ['subs.srt', '2048'],
        ],
        trackers    => ['udp://tracker.example.com:6969'],
        identifiers => ['imdb:tt1234567'],
        hashtags    => ['movie', 'hd'],
    );
    my $torrent = Net::Nostr::Torrent->from_event($event);
    ok($torrent, 'from_event returns object');
    is($torrent->info_hash, 'abcd1234abcd1234abcd1234abcd1234abcd1234', 'info_hash');
    is($torrent->title, 'Test Torrent', 'title');
    is($torrent->description, 'Description here', 'description');
    is($torrent->files, [
        ['video.mkv', '1073741824'],
        ['subs.srt', '2048'],
    ], 'files');
    is($torrent->trackers, ['udp://tracker.example.com:6969'], 'trackers');
    is($torrent->identifiers, ['imdb:tt1234567'], 'identifiers');
    is($torrent->hashtags, ['movie', 'hd'], 'hashtags');
};

subtest 'from_event: minimal' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Minimal',
    );
    my $torrent = Net::Nostr::Torrent->from_event($event);
    is($torrent->info_hash, 'abcd1234abcd1234abcd1234abcd1234abcd1234', 'info_hash');
    is($torrent->title, 'Minimal', 'title');
    is($torrent->description, '', 'empty description');
    is($torrent->files, [], 'no files');
    is($torrent->trackers, [], 'no trackers');
    is($torrent->identifiers, [], 'no identifiers');
    is($torrent->hashtags, [], 'no hashtags');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::Torrent->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# Kind 2004: Torrent Comments
###############################################################################

subtest 'comment: kind 2004' => sub {
    my $event = Net::Nostr::Torrent->comment(
        pubkey  => $PK,
        content => 'Great torrent!',
        tags    => [['e', 'b' x 64, '', 'root']],
    );
    is($event->kind, 2004, 'kind is 2004');
    is($event->content, 'Great torrent!', 'content');
};

# Spec: works exactly like kind 1, should follow NIP-10 for tagging
subtest 'comment: NIP-10 tagging' => sub {
    my $torrent_id = 'b' x 64;
    my $event = Net::Nostr::Torrent->comment(
        pubkey  => $PK,
        content => 'Nice!',
        tags    => [
            ['e', $torrent_id, '', 'root'],
            ['p', 'c' x 64],
        ],
    );
    is($event->kind, 2004, 'kind');
    my @etags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($etags[0][1], $torrent_id, 'e tag references torrent');
    is($etags[0][3], 'root', 'root marker');
    my @ptags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($ptags[0][1], 'c' x 64, 'p tag');
};

subtest 'from_event: parses comment (kind 2004)' => sub {
    my $event = Net::Nostr::Torrent->comment(
        pubkey  => $PK,
        content => 'A comment',
        tags    => [['e', 'b' x 64, '', 'root']],
    );
    my $torrent = Net::Nostr::Torrent->from_event($event);
    ok($torrent, 'from_event returns object for 2004');
    is($torrent->description, 'A comment', 'description from content');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid torrent' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title     => 'Test',
    );
    ok(Net::Nostr::Torrent->validate($event), 'valid torrent');
};

subtest 'validate: valid comment' => sub {
    my $event = Net::Nostr::Torrent->comment(
        pubkey  => $PK,
        content => 'Nice!',
        tags    => [['e', 'b' x 64, '', 'root']],
    );
    ok(Net::Nostr::Torrent->validate($event), 'valid comment');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::Torrent->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate: torrent requires x tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 2003,
        content => '',
        tags    => [['title', 'Test']],
    );
    like(
        dies { Net::Nostr::Torrent->validate($event) },
        qr/x.*tag/i,
        'rejects missing x tag'
    );
};

subtest 'validate: torrent requires title tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PK,
        kind    => 2003,
        content => '',
        tags    => [['x', 'abc123']],
    );
    like(
        dies { Net::Nostr::Torrent->validate($event) },
        qr/title.*tag/i,
        'rejects missing title tag'
    );
};

###############################################################################
# to_event: required fields
###############################################################################

subtest 'to_event: requires info_hash' => sub {
    like(
        dies {
            Net::Nostr::Torrent->to_event(
                pubkey => $PK,
                title  => 'Test',
            )
        },
        qr/info_hash/i,
        'requires info_hash'
    );
};

subtest 'to_event: requires title' => sub {
    like(
        dies {
            Net::Nostr::Torrent->to_event(
                pubkey    => $PK,
                info_hash => 'abc123',
            )
        },
        qr/title/i,
        'requires title'
    );
};

###############################################################################
# created_at passthrough
###############################################################################

subtest 'created_at passthrough' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey     => $PK,
        info_hash  => 'abcd1234abcd1234abcd1234abcd1234abcd1234',
        title      => 'Test',
        created_at => 1700000000,
    );
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Torrent->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

done_testing;
