use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::ATProto::OAuth::SessionStore::SQLite qw//;
use Mojo::Promise;

# Full, realistic hashrefs (as Mojo::ATProto::OAuth itself builds them) -
# unlike the in-memory store, SQLite::SessionStore enforces NOT NULL on
# the fields the contract documents as always-present.
sub auth_request_fixture {
    return {
        state                            => 'state-1',
        account_did                      => 'did:plc:aaaaaaaaaaaaaaaaaaaaaaaa',
        handle                           => 'alice.example',
        host_url                         => 'https://pds.example.com',
        auth_server_url                  => 'https://auth.example.com',
        auth_server_token_endpoint       => 'https://auth.example.com/token',
        auth_server_revocation_endpoint  => 'https://auth.example.com/revoke',
        scopes                           => ['atproto', 'transition:generic'],
        request_uri                      => 'urn:ietf:params:oauth:request_uri:abc',
        pkce_verifier                    => 'verifier-abc',
        dpop_authserver_nonce            => 'nonce-1',
        dpop_private_key_pem             => 'PEM-DATA-1',
        upgrade_session_id               => undef,
        client_state                     => {csrf => 'xyz'},
        extra                            => undef,
    };
}

sub session_fixture {
    return {
        account_did                      => 'did:plc:aaaaaaaaaaaaaaaaaaaaaaaa',
        session_id                       => 'state-1',
        handle                           => 'alice.example',
        host_url                         => 'https://pds.example.com',
        auth_server_url                  => 'https://auth.example.com',
        auth_server_token_endpoint       => 'https://auth.example.com/token',
        auth_server_revocation_endpoint  => 'https://auth.example.com/revoke',
        scopes                           => ['atproto', 'transition:generic'],
        access_token                     => 'tok-1',
        refresh_token                    => 'ref-1',
        dpop_authserver_nonce            => 'nonce-2',
        dpop_host_nonce                  => 'nonce-3',
        dpop_private_key_pem             => 'PEM-DATA-1',
    };
}

subtest 'auth request round-trip' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    my $info  = auth_request_fixture();

    $store->save_auth_request($info);
    is($store->get_auth_request('state-1'), $info, 'round-trips unchanged, including client_state and a NULL extra');

    $store->delete_auth_request('state-1');
    like(dies { $store->get_auth_request('state-1') }, qr/no auth request found/, 'deleted row is gone');
};

subtest 'get_auth_request dies with a matching message on a miss' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    like(dies { $store->get_auth_request('nonexistent') }, qr/no auth request found/, 'miss dies with the expected message');
    ok(lives { $store->delete_auth_request('nonexistent') }, 'deleting a nonexistent state is a silent no-op');
};

subtest 'session round-trip, keyed on the (account_did, session_id) pair' => sub {
    my $store   = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    my $session = session_fixture();

    $store->save_session($session);
    is($store->get_session('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1'), $session, 'round-trips unchanged');

    like(dies { $store->get_session('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'sess-2') }, qr/no session found/, 'a different session_id under the same did misses');
    like(dies { $store->get_session('did:plc:bbbbbbbbbbbbbbbbbbbbbbbb', 'state-1') }, qr/no session found/, 'a different account_did under the same session_id misses');

    $store->delete_session('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1');
    like(dies { $store->get_session('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1') }, qr/no session found/, 'deleted row is gone');
};

subtest 'save_session upserts by (account_did, session_id) rather than duplicating' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    $store->save_session(session_fixture());

    my $upgraded = session_fixture();
    $upgraded->{access_token} = 'tok-2';
    $upgraded->{scopes}       = ['atproto', 'transition:generic', 'transition:chat.bsky'];
    $store->save_session($upgraded);

    my $fetched = $store->get_session('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1');
    is($fetched->{access_token}, 'tok-2', 'second save overwrote the first, in place');
    is($fetched->{scopes}, ['atproto', 'transition:generic', 'transition:chat.bsky'], 'scopes updated too, not just the row identity');
};

subtest 'the _p methods mirror the sync ones' => sub {
    my $store = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    my $info  = auth_request_fixture();

    $store->save_auth_request_p($info)->wait;
    my $fetched;
    $store->get_auth_request_p('state-1')->then(sub ($i) { $fetched = $i })->wait;
    is($fetched, $info, 'save_auth_request_p / get_auth_request_p round-trip');

    my $err;
    $store->get_auth_request_p('nonexistent')->catch(sub ($e) { $err = $e })->wait;
    like($err, qr/no auth request found/, 'get_auth_request_p rejects (not dies) on a miss, same message');

    $store->delete_auth_request_p('state-1')->wait;
    my $err2;
    $store->get_auth_request_p('state-1')->catch(sub ($e) { $err2 = $e })->wait;
    like($err2, qr/no auth request found/, 'delete_auth_request_p removed the row');

    my $session = session_fixture();
    $store->save_session_p($session)->wait;
    my $fetched_session;
    $store->get_session_p('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1')->then(sub ($s) { $fetched_session = $s })->wait;
    is($fetched_session, $session, 'save_session_p / get_session_p round-trip');

    $store->delete_session_p('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1')->wait;
    my $err3;
    $store->get_session_p('did:plc:aaaaaaaaaaaaaaaaaaaaaaaa', 'state-1')->catch(sub ($e) { $err3 = $e })->wait;
    like($err3, qr/no session found/, 'delete_session_p removed the row');
};

subtest 'two stores are independent databases' => sub {
    my $store_a = Mojo::ATProto::OAuth::SessionStore::SQLite->new;
    my $store_b = Mojo::ATProto::OAuth::SessionStore::SQLite->new;

    $store_a->save_auth_request(auth_request_fixture());
    like(dies { $store_b->get_auth_request('state-1') }, qr/no auth request found/, 'a fresh instance does not see another instance\'s data');
};

done_testing;
