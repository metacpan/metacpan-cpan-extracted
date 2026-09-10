#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use Punk ();

# Names on websocket and sse routes.
#
# Both keywords build a GET route by calling route(), then record their own
# options hash for the compiler to stamp onto that record. `name` is a ROUTE
# option, so it is forwarded to route() - where the recording, stamping
# and duplicate croak all run unchanged - and then DROPPED from the copy that
# becomes the transport's configuration, which does not know the key.

sub cb { $_[0] }

{
    my $app = eval {
        package NW;
        use Punk;
        host 'https://example.com';
        websocket '/chat'     => \&main::cb, { name => 'chat',
                                               protocols => ['v1'] };
        websocket '/room/:id' => \&main::cb, { name => 'room' };
        sse       '/feed'     => \&main::cb, { name => 'feed',
                                               heartbeat => 30 };
        sse       '/feed/:id' => \&main::cb, { name => 'feed_one' };
        get '/u' => sub {
            my $c = shift;
            $c->text(join "\n",
                $c->url_for('chat'),
                $c->url_for('room', id => 7),
                $c->url_for('feed'),
                $c->url_for('feed_one', id => 9),
                $c->url_for('chat', absolute => 1));
        }, { name => 'u' };
        __PACKAGE__->to_app;
    };
    ok $app, 'named websocket and sse routes compile' or diag $@;

    my @u = split /\n/, join '', @{ hit($app, path => '/u')->[2] };
    is $u[0], '/chat',      'a websocket route builds its path';
    is $u[1], '/room/7',    'and captures like any other route';
    is $u[2], '/feed',      'an sse route builds its path';
    is $u[3], '/feed/9',    'and captures too';
    is $u[4], 'https://example.com/chat',
        'absolute works - the scheme swap to wss is the application\'s, and '
      . 'the POD says so';
}

{
    # the transport's own options still reach it, and `name` does not
    my $recs = NW->punk_app->{router}->records;
    my ($chat) = grep { ($_->{path} // '') eq '/chat' } @$recs;
    my ($feed) = grep { ($_->{path} // '') eq '/feed' } @$recs;

    is $chat->{name}, 'chat', 'the name is stamped onto the compiled record';
    is ref $chat->{ws}, 'HASH', 'and the websocket options are stamped too';
    is_deeply $chat->{ws}, { protocols => ['v1'] },
        'with `name` dropped - Punk::WebSocket does not know that key';

    is $feed->{name}, 'feed', 'the same for sse';
    is_deeply $feed->{sse}, { heartbeat => 30 },
        'and its options are its own';
}

{
    # the options hashref an application reuses between declarations must not
    # lose its key to the first one
    my %opts = ( name => 'a', heartbeat => 5 );
    my $app = eval {
        package NWR;
        use Punk;
        sse '/a' => \&main::cb, { %opts };
        __PACKAGE__->to_app;
    };
    ok $app, 'a declaration from a copied options hash compiles' or diag $@;
    is $opts{name}, 'a',
        'and the caller\'s hashref still has its name - the delete is on the copy';
}

# ---- the croaks -----------------------------------------------------------

sub boot_fails {
    my ($body, $like, $what) = @_;
    my $pkg = 'NWX' . int(rand 1e9);
    eval "package $pkg; use Punk; $body; ${pkg}->to_app; 1";
    like $@ || '', $like, $what;
}

boot_fails q{websocket '/w' => sub {}, { name => 'a.b' }},
    qr/websocket name 'a\.b' may not contain '\.'/,
    'a websocket name is held to the same rule, and the croak says which '
  . 'keyword';

boot_fails q{sse '/s' => sub {}, { name => 'query' }},
    qr/'query' is reserved and cannot be a sse name/,
    'and so is an sse name';

boot_fails q{websocket '/w' => sub {}, { nmae => 'a' }},
    qr/unknown websocket option\(s\) nmae/,
    'a typo in the option key still croaks as it did';

boot_fails q{get '/x' => sub {}, { name => 'dup' };
             websocket '/w' => sub {}, { name => 'dup' }},
    qr/route name 'dup' is declared twice: GET \/x and GET \/w/,
    'a websocket route sharing a name with a route croaks, naming both';

done_testing;
