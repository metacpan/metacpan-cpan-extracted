use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Torrent;

my $PK = 'a' x 64;

###############################################################################
# POD example: to_event
###############################################################################

subtest 'POD: to_event' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $PK,
        info_hash   => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title       => 'Example Torrent',
        content     => 'A long description',
        files       => [
            ['video.mkv', '4294967296'],
            ['subs.srt', '2048'],
        ],
        trackers    => ['udp://tracker.example.com:6969'],
        identifiers => ['imdb:tt15239678', 'tmdb:movie:693134'],
        hashtags    => ['movie', '4k'],
    );
    is($event->kind, 2003, 'kind');
    my @x = grep { $_->[0] eq 'x' } @{$event->tags};
    is($x[0][1], 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3', 'info_hash');
};

###############################################################################
# POD example: comment
###############################################################################

subtest 'POD: comment' => sub {
    my $torrent_event_id = 'b' x 64;
    my $comment = Net::Nostr::Torrent->comment(
        pubkey  => $PK,
        content => 'Great torrent!',
        tags    => [['e', $torrent_event_id, '', 'root']],
    );
    is($comment->kind, 2004, 'kind');
    is($comment->content, 'Great torrent!', 'content');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title     => 'Example Torrent',
    );
    my $torrent = Net::Nostr::Torrent->from_event($event);
    is($torrent->title, 'Example Torrent');
    is($torrent->info_hash, 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::Torrent->to_event(
        pubkey    => $PK,
        info_hash => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title     => 'Example Torrent',
    );
    ok(Net::Nostr::Torrent->validate($event), 'validate returns true');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $torrent = Net::Nostr::Torrent->new(
        info_hash => 'abc123',
        title     => 'Example',
    );
    is($torrent->info_hash, 'abc123');
    is($torrent->title, 'Example');
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

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::Torrent',
        qw(new to_event comment from_event validate
           info_hash title description files trackers identifiers hashtags));
};

done_testing;
