# t/store-cookie.t
#
# Test cookie-based session store (encrypted client-side storage)
#
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;
use PAGI::Middleware::Session::Store::Cookie;
use PAGI::Middleware::Session;

sub run_async (&) { $_[0]->()->get }

my $SECRET = 'a-secret-key-that-is-at-least-32-bytes-long!!';

subtest 'constructor requires secret' => sub {
    ok(dies { PAGI::Middleware::Session::Store::Cookie->new() },
       'dies without secret');
};

subtest 'set returns encrypted blob (not the ID)' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $blob;
    run_async {
        async sub {
            $blob = await $store->set('sess-1', { user_id => 42 });
        }->();
    };

    ok(defined $blob, 'set returns a value');
    isnt($blob, 'sess-1', 'not the session ID');
    unlike($blob, qr/user_id/, 'data is not plaintext');
};

subtest 'get decodes blob back to data' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my ($blob, $data);
    run_async {
        async sub {
            $blob = await $store->set('sess-1', { user_id => 42, _id => 'sess-1' });
            $data = await $store->get($blob);
        }->();
    };

    ok(defined $data, 'get returns data');
    is($data->{user_id}, 42, 'user_id preserved');
    is($data->{_id}, 'sess-1', 'session ID preserved');
};

subtest 'get returns undef for tampered data' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my ($blob, $data);
    run_async {
        async sub {
            $blob = await $store->set('sess-1', { user_id => 42 });
            # Tamper with the blob
            my $tampered = $blob;
            substr($tampered, 5, 1) = substr($tampered, 5, 1) eq 'A' ? 'B' : 'A';
            $data = await $store->get($tampered);
        }->();
    };

    is($data, undef, 'tampered data returns undef');
};

subtest 'get returns undef for garbage input' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $data;
    run_async {
        async sub {
            $data = await $store->get('not-a-valid-blob');
        }->();
    };
    is($data, undef, 'garbage returns undef');
};

subtest 'get returns undef for undef input' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $data;
    run_async {
        async sub {
            $data = await $store->get(undef);
        }->();
    };
    is($data, undef, 'undef returns undef');
};

subtest 'different secrets produce different blobs' => sub {
    my $store1 = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $store2 = PAGI::Middleware::Session::Store::Cookie->new(secret => 'different-secret-also-32-bytes!!x');

    my ($blob1, $blob2);
    my $data = { user_id => 42 };
    run_async {
        async sub {
            $blob1 = await $store1->set('s', $data);
            $blob2 = await $store2->set('s', $data);
        }->();
    };

    isnt($blob1, $blob2, 'different secrets produce different blobs');
};

subtest 'wrong secret cannot decode' => sub {
    my $store1 = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $store2 = PAGI::Middleware::Session::Store::Cookie->new(secret => 'wrong-secret-also-32-bytes-long!x');

    my ($blob, $data);
    run_async {
        async sub {
            $blob = await $store1->set('s', { user_id => 42 });
            $data = await $store2->get($blob);
        }->();
    };
    is($data, undef, 'wrong secret returns undef');
};

subtest 'delete is a no-op' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $result;
    run_async {
        async sub {
            $result = await $store->delete('anything');
        }->();
    };
    ok(defined $result, 'delete returns something');
};

subtest 'round-trip through middleware pattern' => sub {
    # Simulate: State extracts cookie value, Store decodes it,
    # app modifies session, Store encodes it, State injects cookie
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);

    my ($blob, $restored, $blob2, $restored2);
    run_async {
        async sub {
            # First request: new session
            my $session = { _id => 'new-sess', _created => time(), counter => 0 };
            $blob = await $store->set('new-sess', $session);

            # Second request: restore from cookie blob
            $restored = await $store->get($blob);
        }->();
    };
    is($restored->{counter}, 0, 'counter restored');

    run_async {
        async sub {
            # Modify and save again
            $restored->{counter} = 1;
            $blob2 = await $store->set($restored->{_id}, $restored);

            # Third request: verify update persisted
            $restored2 = await $store->get($blob2);
        }->();
    };
    is($restored2->{counter}, 1, 'counter updated');
};

# ===================
# Regression: mutating an existing session through the real middleware
# must produce a Set-Cookie carrying the mutated data (the Parley bug —
# see PAGI-Tools docs/superpowers/specs/2026-07-13-session-mutation-setcookie-design.md).
# Store::Cookie has no server-side copy, so a discarded transport here is
# a correctness bug, not just a missed refresh.
# ===================

subtest 'mutating an existing session round-trips through the real middleware + Store::Cookie' => sub {
    my $store = PAGI::Middleware::Session::Store::Cookie->new(secret => $SECRET);
    my $session_mw = PAGI::Middleware::Session->new(
        secret => $SECRET,
        store  => $store,
    );

    my $make_scope = sub {
        my (%opts) = @_;
        return {
            type    => 'http',
            method  => $opts{method} // 'GET',
            path    => $opts{path} // '/',
            headers => $opts{headers} // [],
        };
    };

    my $set_cookie = sub {
        my ($events) = @_;
        my ($cookie) = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events->[0]{headers}};
        return $cookie;
    };

    # Request 1: create a session and set counter => 1
    my @events1;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.session'}{counter} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async {
        $session_mw->wrap($app1)->($make_scope->(), async sub { {} }, async sub { push @events1, $_[0] })
    };

    my $cookie1 = $set_cookie->(\@events1);
    ok(defined $cookie1, 'request 1 (new session) gets a Set-Cookie');
    my ($blob1) = $cookie1 =~ /pagi_session=([^;]+)/;
    ok(defined $blob1, 'session blob extracted from request 1 cookie');

    # Request 2: mutate the existing session (no regenerate) — this is the
    # exact shape that silently dropped data before the fix.
    my @events2;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.session'}{counter} = 2;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope2 = $make_scope->(headers => [['Cookie', "pagi_session=$blob1"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events2, $_[0] })
    };

    my $cookie2 = $set_cookie->(\@events2);
    ok(defined $cookie2, 'request 2 (mutation of existing session) gets a fresh Set-Cookie');
    my ($blob2) = $cookie2 =~ /pagi_session=([^;]+)/;
    ok(defined $blob2, 'session blob extracted from request 2 cookie');

    # Decrypt directly via the store's own get() — this is the assertion
    # that catches the original bug: without the fix, request 2 emits no
    # Set-Cookie at all, so $blob2 would be undef and this decrypt would
    # never happen; with the fix, it decrypts to the mutated value.
    my $decoded;
    run_async {
        async sub { $decoded = await $store->get($blob2) }->();
    };
    ok(defined $decoded, 'store decrypts the Set-Cookie blob from the mutation response');
    is($decoded->{counter}, 2, 'decrypted blob carries the mutated value, not the stale one');

    # Request 3: pure read of the existing session — the dirty check must
    # compare equal through a real Store::Cookie decrypt (numbers, booleans,
    # and reserved keys included), so no Set-Cookie is emitted. Guards the
    # inverse regression: a false-dirty here would re-emit the cookie on
    # every response.
    my (@events3, $seen);
    my $app3 = async sub {
        my ($scope, $receive, $send) = @_;
        $seen = $scope->{'pagi.session'}{counter};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope3 = $make_scope->(headers => [['Cookie', "pagi_session=$blob2"]]);
    run_async {
        $session_mw->wrap($app3)->($scope3, async sub { {} }, async sub { push @events3, $_[0] })
    };

    is($seen, 2, 'request 3 (pure read) sees the mutated session');
    ok(!defined $set_cookie->(\@events3), 'pure read of an existing session emits no Set-Cookie');
};

done_testing;
