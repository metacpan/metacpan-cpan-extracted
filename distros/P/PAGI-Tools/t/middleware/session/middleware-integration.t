#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

use PAGI::Middleware::Session;
use PAGI::Middleware::Session::State::Header;
use PAGI::Middleware::Session::Store::Memory;
use PAGI::Session;

my $loop = IO::Async::Loop->new;

sub run_async (&) {
    my ($code) = @_;
    $loop->await($code->());
}

sub make_scope {
    my (%opts) = @_;
    return {
        type    => $opts{type} // 'http',
        method  => $opts{method} // 'GET',
        path    => $opts{path} // '/',
        headers => $opts{headers} // [],
    };
}

# ===================
# Integration: explicit State and Store
# ===================

subtest 'new API with explicit state and store' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all();

    my $state = PAGI::Middleware::Session::State::Header->new(
        header_name => 'X-Session-ID',
    );
    my $store = PAGI::Middleware::Session::Store::Memory->new();

    my $session_mw = PAGI::Middleware::Session->new(
        secret => 'integration-secret',
        state  => $state,
        store  => $store,
    );

    # First request: create session
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 99;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    ok defined $session_id, 'session ID created';
    like $session_id, qr/^[a-f0-9]{64}$/, 'session ID is SHA256 hash';

    # Second request: restore session via header
    my $captured_session;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $scope2 = make_scope(headers => [['X-Session-ID', $session_id]]);
    run_async { $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { }) };

    is $captured_session->{user_id}, 99, 'session data restored via header state';
};

# ===================
# Integration: default API still works
# ===================

subtest 'default API still works' => sub {
    PAGI::Middleware::Session->clear_sessions();

    my $session_mw = PAGI::Middleware::Session->new(secret => 'default-secret');

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $session_mw->wrap($app);
    my $scope = make_scope();

    my @events;
    my $receive = async sub { {} };
    my $send = async sub {
        my ($event) = @_; push @events, $event };

    run_async { $wrapped->($scope, $receive, $send) };

    my @set_cookies = map { $_->[1] }
        grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    ok scalar(@set_cookies), 'has Set-Cookie header with default config';
    like $set_cookies[0], qr/pagi_session=/, 'cookie name is pagi_session';
};

# ===================
# Integration: header state does not set cookies
# ===================

subtest 'header state does not set cookies' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all();

    my $state = PAGI::Middleware::Session::State::Header->new(
        header_name => 'X-Session-ID',
    );
    my $store = PAGI::Middleware::Session::Store::Memory->new();

    my $session_mw = PAGI::Middleware::Session->new(
        secret => 'header-secret',
        state  => $state,
        store  => $store,
    );

    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $session_mw->wrap($app);
    my $scope = make_scope();

    my @events;
    my $receive = async sub { {} };
    my $send = async sub {
        my ($event) = @_; push @events, $event };

    run_async { $wrapped->($scope, $receive, $send) };

    my @set_cookies = map { $_->[1] }
        grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    is scalar(@set_cookies), 0, 'no Set-Cookie header when using header state';
};

# ===================
# Idempotency tests
# ===================

subtest 'idempotency: skips if session already in scope' => sub {
    PAGI::Middleware::Session->clear_sessions();

    my $session_mw = PAGI::Middleware::Session->new(secret => 'idem-secret');

    my $pre_existing_session = { user_id => 42, _id => 'pre-existing-id' };

    my $captured_scope;
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $session_mw->wrap($app);

    # Pre-populate pagi.session in scope
    my $scope = make_scope();
    $scope->{'pagi.session'} = $pre_existing_session;

    my @events;
    my $receive = async sub { {} };
    my $send = async sub {
        my ($event) = @_; push @events, $event };

    run_async { $wrapped->($scope, $receive, $send) };

    # Session should be the original, not a new one
    is $captured_scope->{'pagi.session'}, $pre_existing_session,
        'outer session preserved (same reference)';
    is $captured_scope->{'pagi.session'}{user_id}, 42,
        'outer session data intact';

    # No Set-Cookie should be added
    my @set_cookies = map { $_->[1] }
        grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    is scalar(@set_cookies), 0, 'no Set-Cookie added when session already exists';
};

subtest 'idempotency: normal behavior when no pre-existing session' => sub {
    PAGI::Middleware::Session->clear_sessions();

    my $session_mw = PAGI::Middleware::Session->new(secret => 'idem-secret-2');

    my $captured_scope;
    my $app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my $wrapped = $session_mw->wrap($app);
    my $scope = make_scope();

    my @events;
    my $receive = async sub { {} };
    my $send = async sub {
        my ($event) = @_; push @events, $event };

    run_async { $wrapped->($scope, $receive, $send) };

    ok exists $captured_scope->{'pagi.session'}, 'session created when none pre-exists';
    ok exists $captured_scope->{'pagi.session_id'}, 'session_id set';
    like $captured_scope->{'pagi.session_id'}, qr/^[a-f0-9]{64}$/, 'valid session ID format';

    my @set_cookies = map { $_->[1] }
        grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    ok scalar(@set_cookies), 'Set-Cookie header added for new session';
};

# ===================
# Integration: destroy deletes session and clears cookie
# ===================

subtest 'destroy deletes session and clears cookie' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'test-secret');

    # Create a session first
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 42;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Now destroy it
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.session'}{_destroyed} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my @events;
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events, $_[0] })
    };

    # Should have a Set-Cookie with Max-Age=0
    my @cookies = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    ok(scalar @cookies, 'has Set-Cookie header');
    like($cookies[0], qr/Max-Age=0/, 'cookie expired');

    # Session should be gone from store
    my $app3 = async sub {
        my ($scope, $receive, $send) = @_;
        # Session should NOT be restored — it was destroyed
        ok(!exists $scope->{'pagi.session'}{user_id}, 'session data gone after destroy');
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope3 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async { $session_mw->wrap($app3)->($scope3, async sub { {} }, async sub { }) };
};

# ===================
# Integration: regenerate creates new session ID and deletes old
# ===================

subtest 'regenerate creates new session ID and deletes old' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'test-secret');

    # Create a session
    my $old_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $old_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 42;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Regenerate the session ID (simulates post-login)
    my $new_id;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.session'}{_regenerated} = 1;
        $scope->{'pagi.session'}{logged_in} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my @events;
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$old_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events, $_[0] })
    };

    # Extract new session ID from Set-Cookie
    my @cookies = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    ok(scalar @cookies, 'has Set-Cookie header after regenerate');
    ($new_id) = $cookies[0] =~ /pagi_session=([a-f0-9]+)/;
    ok($new_id, 'new session ID in cookie');
    isnt($new_id, $old_id, 'new ID differs from old ID');

    # Old session ID should not load data
    my $captured_session;
    my $app3 = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope3 = make_scope(headers => [['Cookie', "pagi_session=$old_id"]]);
    run_async { $session_mw->wrap($app3)->($scope3, async sub { {} }, async sub { }) };
    ok(!$captured_session->{user_id}, 'old session ID returns no data');

    # New session ID should have the data
    my $scope4 = make_scope(headers => [['Cookie', "pagi_session=$new_id"]]);
    run_async { $session_mw->wrap($app3)->($scope4, async sub { {} }, async sub { }) };
    is($captured_session->{user_id}, 42, 'data preserved under new ID');
    is($captured_session->{logged_in}, 1, 'new data also present');
};

# ===================
# Integration: mutating an existing session emits a fresh Set-Cookie
# ===================

subtest 'mutating an existing session emits a fresh Set-Cookie carrying the new data' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'dirty-secret');

    # Request 1: create session, set counter => 1
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{counter} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Request 2: mutate existing session via PAGI::Session->set (not new, not regenerated)
    my @events2;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        PAGI::Session->new($scope)->set(counter => 2);
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events2, $_[0] })
    };

    my @cookies2 = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events2[0]{headers}};
    ok(scalar(@cookies2), 'Set-Cookie header emitted on mutation of existing session');

    # Request 3: reuse cookie from request 2, confirm mutated value round-trips
    my $captured_session;
    my $app3 = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope3 = make_scope(headers => [['Cookie', $cookies2[0]]]);
    run_async { $session_mw->wrap($app3)->($scope3, async sub { {} }, async sub { }) };
    is($captured_session->{counter}, 2, 'mutated value restored on next request');
};

# ===================
# Integration: mutating via $session->data directly is also observed
# ===================

subtest 'mutating via $session->data directly is also observed' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'dirty-data-secret');

    # Request 1: create session, set counter => 1
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{counter} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Request 2: mutate existing session via raw ->data hashref, bypassing set/delete/clear
    my @events2;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        PAGI::Session->new($scope)->data->{counter} = 2;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events2, $_[0] })
    };

    my @cookies2 = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events2[0]{headers}};
    ok(scalar(@cookies2), 'Set-Cookie header emitted on direct ->data mutation');

    # Request 3: reuse cookie from request 2, confirm mutated value round-trips
    my $captured_session;
    my $app3 = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope3 = make_scope(headers => [['Cookie', $cookies2[0]]]);
    run_async { $session_mw->wrap($app3)->($scope3, async sub { {} }, async sub { }) };
    is($captured_session->{counter}, 2, 'mutated value restored on next request');
};

# ===================
# Integration: pure read request emits no new Set-Cookie
# ===================

subtest 'pure read request emits no new Set-Cookie' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'pure-read-secret');

    # Request 1: create session
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{counter} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Request 2: reuse cookie, perform no mutation at all
    my @events2;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        my $value = $scope->{'pagi.session'}{counter};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events2, $_[0] })
    };

    my @cookies2 = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events2[0]{headers}};
    is(scalar(@cookies2), 0, 'no Set-Cookie header emitted on pure-read request');
};

# ===================
# Integration: regenerate after mutation emits exactly one Set-Cookie
# ===================

subtest 'regenerate after mutation emits exactly one Set-Cookie' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'regen-mutate-secret');

    # Create a session
    my $old_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $old_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 42;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Regenerate the session ID while also mutating data in the same request
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        $scope->{'pagi.session'}{_regenerated} = 1;
        $scope->{'pagi.session'}{logged_in} = 1;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };

    my @events;
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$old_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events, $_[0] })
    };

    my @cookies = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events[0]{headers}};
    is(scalar(@cookies), 1, 'exactly one Set-Cookie header on regenerate-after-mutate, no double-inject');
};

# ===================
# Integration: expired-then-reloaded session with no snapshot is treated as new for dirty purposes
# ===================

subtest 'expired-then-reloaded session with no snapshot is treated as new for dirty purposes' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'expired-secret', expire => -1);

    # Request 1: create a session (immediately expired due to expire => -1)
    my $session_id;
    my $app1 = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($app1)->(make_scope(), async sub { {} }, async sub { }) };

    # Request 2: present the (now-expired) cookie; middleware falls through to
    # create-new-session path, so $snapshot is undef and $is_new is 1
    my @events2;
    my $app2 = async sub {
        my ($scope, $receive, $send) = @_;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    my $scope2 = make_scope(headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async {
        $session_mw->wrap($app2)->($scope2, async sub { {} }, async sub { push @events2, $_[0] })
    };

    my @cookies2 = map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$events2[0]{headers}};
    ok(scalar(@cookies2), 'Set-Cookie still emitted for expired-then-recreated session');
};

# ===================
# Non-HTTP scopes (websocket, sse, ...): read-only, store-agnostic session
# support -- store-agnostic is proven here by using Store::Memory (a
# completely different store than the cookie-as-transport Store::Cookie a
# sibling dist exercises for the same feature) with the SAME extract/get
# path the http branch already uses.
# ===================

subtest 'websocket-scope upgrade with a valid session sees the same data an http request would' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'ws-secret');

    # Establish a real session over a normal 'http' request first.
    my $session_id;
    my $http_app = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 7;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($http_app)->(make_scope(), async sub { {} }, async sub { }) };
    ok $session_id, 'http request established a real session';

    # A websocket-typed scope presenting the SAME session cookie -> the
    # wrapped app sees the loaded session data, read-only (no send event
    # of any kind -- an upgrade handshake, not an HTTP response).
    my ($captured_session, $captured_session_id);
    my $ws_app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        $captured_session_id = $scope->{'pagi.session_id'};
        return;
    };
    my $ws_scope = make_scope(type => 'websocket', headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async { $session_mw->wrap($ws_app)->($ws_scope, async sub { {} }, async sub { }) };

    is $captured_session->{user_id}, 7, 'websocket scope sees the same session data an http request would';
    is $captured_session_id, $session_id, 'websocket scope sees the real session id';
};

# SSE scopes (real PAGI::Server::Connection::_create_sse_scope) are typed
# 'sse' -- a genuinely distinct scope type from 'http', NOT 'http' plus an
# extension flag -- and carry the SAME 'headers' key an http/websocket scope
# does (confirmed reading the installed PAGI::Server source directly). The
# non-http branch added for websockets makes no websocket-specific
# assumption anywhere (it only ever checks scope type != 'http' and the
# presence of a 'headers' key), so this proves that same read-only session
# support covers 'sse' scopes too, with no additional code -- per John's
# own explicit requirement: "if there is a session then websockets and SSE
# need to see it."
subtest 'sse-scope request with a valid session sees the same data an http request would' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'sse-secret');

    my $session_id;
    my $http_app = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 9;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($http_app)->(make_scope(), async sub { {} }, async sub { }) };
    ok $session_id, 'http request established a real session';

    my ($captured_session, $captured_session_id);
    my $sse_app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        $captured_session_id = $scope->{'pagi.session_id'};
        return;
    };
    my $sse_scope = make_scope(type => 'sse', headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async { $session_mw->wrap($sse_app)->($sse_scope, async sub { {} }, async sub { }) };

    is $captured_session->{user_id}, 9, 'sse scope sees the same session data an http request would';
    is $captured_session_id, $session_id, 'sse scope sees the real session id';
};

subtest 'sse-scope request with an absent/garbage session gets an empty, present session (no crash)' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'sse-miss-secret');

    for my $case (
        { name => 'no cookie at all',    headers => [] },
        { name => 'unresolvable cookie', headers => [['Cookie', 'pagi_session=not-a-real-session-id']] },
    ) {
        my ($captured_session, $captured_has_id);
        my $sse_app = async sub {
            my ($scope, $receive, $send) = @_;
            $captured_session = $scope->{'pagi.session'};
            $captured_has_id  = exists $scope->{'pagi.session_id'};
            return;
        };
        my $sse_scope = make_scope(type => 'sse', headers => $case->{headers});

        my $survived = eval {
            run_async { $session_mw->wrap($sse_app)->($sse_scope, async sub { {} }, async sub { }) };
            1;
        };
        ok $survived, "$case->{name}: does not die (no crash)" or diag $@;

        ok defined($captured_session), "$case->{name}: pagi.session is present, not a missing key";
        is $captured_session, {}, "$case->{name}: pagi.session is an explicit empty hashref";
        ok !$captured_has_id, "$case->{name}: pagi.session_id is not set (no real session to report)";
    }
};

subtest 'websocket-scope upgrade with an absent/garbage session gets an empty, present session (no crash)' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'ws-miss-secret');

    for my $case (
        { name => 'no cookie at all',    headers => [] },
        { name => 'unresolvable cookie', headers => [['Cookie', 'pagi_session=not-a-real-session-id']] },
    ) {
        my ($captured_session, $captured_has_id);
        my $ws_app = async sub {
            my ($scope, $receive, $send) = @_;
            $captured_session = $scope->{'pagi.session'};
            $captured_has_id  = exists $scope->{'pagi.session_id'};
            return;
        };
        my $ws_scope = make_scope(type => 'websocket', headers => $case->{headers});

        my $survived = eval {
            run_async { $session_mw->wrap($ws_app)->($ws_scope, async sub { {} }, async sub { }) };
            1;
        };
        ok $survived, "$case->{name}: does not die (no crash)" or diag $@;

        ok defined($captured_session), "$case->{name}: pagi.session is present, not a missing key";
        is $captured_session, {}, "$case->{name}: pagi.session is an explicit empty hashref";
        ok !$captured_has_id, "$case->{name}: pagi.session_id is not set (no real session to report)";
    }
};

# Review finding (Important): expired-session-on-upgrade is structurally
# rejected by _wrap_non_http (it calls the SAME _is_expired check the http
# branch uses) but was untested anywhere -- the one auth-bypass-shaped edge
# this feature has: an attacker presenting a stale/expired session cookie
# on a WebSocket upgrade must NOT get its data. Ages a real session
# directly in the store (mutating its _last_access, the same field
# _is_expired reads) rather than the shortcut the earlier "expired-then-
# reloaded" http-side test uses (a contrived expire => -1 config) -- this
# exercises _is_expired's own elapsed-time arithmetic instead of bypassing
# it, closer to what real elapsed wall-clock time would produce.
subtest 'websocket-scope upgrade with an EXPIRED session gets an empty, present session (not the stale data)' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $store = PAGI::Middleware::Session::Store::Memory->new();
    my $session_mw = PAGI::Middleware::Session->new(secret => 'ws-expired-secret', store => $store);

    my $session_id;
    my $http_app = async sub {
        my ($scope, $receive, $send) = @_;
        $session_id = $scope->{'pagi.session_id'};
        $scope->{'pagi.session'}{user_id} = 123;
        await $send->({ type => 'http.response.start', status => 200, headers => [] });
        await $send->({ type => 'http.response.body', body => 'OK', more => 0 });
    };
    run_async { $session_mw->wrap($http_app)->(make_scope(), async sub { {} }, async sub { }) };
    ok $session_id, 'http request established a real session';

    my $session_data = $store->get($session_id)->get;
    ok $session_data, 'session data fetched directly from the store';
    $session_data->{_last_access} = time() - 100_000; # WAY past the default 3600s expire
    $store->set($session_id, $session_data)->get;

    my ($captured_session, $captured_has_id);
    my $ws_app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_session = $scope->{'pagi.session'};
        $captured_has_id  = exists $scope->{'pagi.session_id'};
        return;
    };
    my $ws_scope = make_scope(type => 'websocket', headers => [['Cookie', "pagi_session=$session_id"]]);
    run_async { $session_mw->wrap($ws_app)->($ws_scope, async sub { {} }, async sub { }) };

    is $captured_session, {}, 'expired session is treated as a miss -- empty hashref, not the stale user_id=>123 data';
    ok !$captured_has_id, 'pagi.session_id is not set for an expired session (no real session to report)';
};

subtest 'a non-http scope with no headers at all (lifespan) is skipped entirely, as before' => sub {
    PAGI::Middleware::Session::Store::Memory->clear_all;
    my $session_mw = PAGI::Middleware::Session->new(secret => 'lifespan-secret');

    my $captured_scope;
    my $lifespan_app = async sub {
        my ($scope, $receive, $send) = @_;
        $captured_scope = $scope;
        return;
    };
    my $lifespan_scope = { type => 'lifespan', state => {} }; # deliberately no 'headers' key
    run_async { $session_mw->wrap($lifespan_app)->($lifespan_scope, async sub { {} }, async sub { }) };

    ok !exists $captured_scope->{'pagi.session'}, 'lifespan scope gets no pagi.session key at all';
    ok !exists $captured_scope->{'pagi.session_id'}, 'lifespan scope gets no pagi.session_id key at all';
};

done_testing;
