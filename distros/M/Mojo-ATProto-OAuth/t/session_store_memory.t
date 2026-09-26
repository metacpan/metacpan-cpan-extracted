use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib 't/lib';
use Mojo::ATProto::OAuth::SessionStore::Memory qw//;
use Mojo::Promise;
use SessionStoreContract qw/update_and_lock_subtests/;

subtest 'auth request round-trip' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $info  = {state => 'state-1', auth_server_url => 'https://auth.example.com', scopes => ['atproto']};

    $store->save_auth_request($info);
    my $fetched = $store->get_auth_request('state-1');
    is($fetched, $info, 'round-trips unchanged');

    $fetched->{scopes} = ['tampered'];
    is($store->get_auth_request('state-1')->{scopes}, ['atproto'], 'get_auth_request returns a shallow copy, not the stored ref itself');

    $store->delete_auth_request('state-1');
    like(dies { $store->get_auth_request('state-1') }, qr/no auth request found/, 'deleted row is gone');
};

subtest 'get_auth_request dies with a matching message on a miss' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    like(dies { $store->get_auth_request('nonexistent') }, qr/no auth request found/, 'miss dies with the expected message');
    ok(lives { $store->delete_auth_request('nonexistent') }, 'deleting a nonexistent state is a silent no-op');
};

subtest 'session round-trip, keyed on the (account_did, session_id) pair' => sub {
    my $store   = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $session = {account_did => 'did:plc:aaa', session_id => 'sess-1', access_token => 'tok-1'};

    $store->save_session($session);
    is($store->get_session('did:plc:aaa', 'sess-1'), $session, 'round-trips unchanged');

    like(dies { $store->get_session('did:plc:aaa', 'sess-2') }, qr/no session found/, 'a different session_id under the same did misses');
    like(dies { $store->get_session('did:plc:bbb', 'sess-1') }, qr/no session found/, 'a different account_did under the same session_id misses');

    $store->delete_session('did:plc:aaa', 'sess-1');
    like(dies { $store->get_session('did:plc:aaa', 'sess-1') }, qr/no session found/, 'deleted row is gone');
};

subtest 'save_session upserts by (account_did, session_id) rather than duplicating' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    $store->save_session({account_did => 'did:plc:aaa', session_id => 'sess-1', access_token => 'tok-1'});
    $store->save_session({account_did => 'did:plc:aaa', session_id => 'sess-1', access_token => 'tok-2'});

    is($store->get_session('did:plc:aaa', 'sess-1')->{access_token}, 'tok-2', 'second save overwrote the first, in place');
};

subtest 'last_state_for_issuer recovers the most recently saved state for a given issuer' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    is($store->last_state_for_issuer('https://auth.example.com'), undef, 'undef when nothing has been saved yet');

    $store->save_auth_request({state => 'state-1', auth_server_url => 'https://auth.example.com'});
    $store->save_auth_request({state => 'state-2', auth_server_url => 'https://someone-else.example.com'});
    $store->save_auth_request({state => 'state-3', auth_server_url => 'https://auth.example.com'});

    is($store->last_state_for_issuer('https://auth.example.com'), 'state-3', 'most recent matching state wins, unrelated issuers ignored');

    $store->delete_auth_request('state-3');
    is($store->last_state_for_issuer('https://auth.example.com'), 'state-1', 'falls back to the next-most-recent once the latest is deleted');
};

subtest 'the _p methods mirror the sync ones' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;

    $store->save_auth_request_p({state => 'state-1', auth_server_url => 'https://auth.example.com'})->wait;
    my $info;
    $store->get_auth_request_p('state-1')->then(sub ($i) { $info = $i })->wait;
    is($info->{state}, 'state-1', 'save_auth_request_p / get_auth_request_p round-trip');

    my $err;
    $store->get_auth_request_p('nonexistent')->catch(sub ($e) { $err = $e })->wait;
    like($err, qr/no auth request found/, 'get_auth_request_p rejects (not dies) on a miss, same message');

    $store->delete_auth_request_p('state-1')->wait;
    my $err2;
    $store->get_auth_request_p('state-1')->catch(sub ($e) { $err2 = $e })->wait;
    like($err2, qr/no auth request found/, 'delete_auth_request_p removed the row');

    $store->save_session_p({account_did => 'did:plc:aaa', session_id => 'sess-1', access_token => 'tok-1'})->wait;
    my $session;
    $store->get_session_p('did:plc:aaa', 'sess-1')->then(sub ($s) { $session = $s })->wait;
    is($session->{access_token}, 'tok-1', 'save_session_p / get_session_p round-trip');

    $store->delete_session_p('did:plc:aaa', 'sess-1')->wait;
    my $err3;
    $store->get_session_p('did:plc:aaa', 'sess-1')->catch(sub ($e) { $err3 = $e })->wait;
    like($err3, qr/no session found/, 'delete_session_p removed the row');
};

update_and_lock_subtests(
    sub { Mojo::ATProto::OAuth::SessionStore::Memory->new },
    sub (%overrides) {
        return {account_did => 'did:plc:aaa', session_id => 'sess-1', access_token => 'tok-1', refresh_token => 'ref-1', dpop_host_nonce => 'nonce-1', %overrides};
    },
);

subtest 'lock_session dies rather than bypassing a pending lock_session_p' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    $store->save_session({account_did => 'did:plc:aaa', session_id => 'sess-1', refresh_token => 'ref-1'});

    my $sync_err;
    $store->lock_session_p('did:plc:aaa', 'sess-1', sub ($current) {
        $sync_err = dies { $store->lock_session('did:plc:aaa', 'sess-1', sub ($c) { return 1 }) };
        return 1;
    })->wait;
    like($sync_err, qr/locked by a pending asynchronous operation/, 'sync lock refused while the async one is held');
    is($store->session_locks, {}, 'the queue entry is cleaned up once the async lock is released');
    is($store->lock_session('did:plc:aaa', 'sess-1', sub ($c) { return 'ok' }), 'ok', 'and the sync lock works again afterwards');
};

done_testing;
