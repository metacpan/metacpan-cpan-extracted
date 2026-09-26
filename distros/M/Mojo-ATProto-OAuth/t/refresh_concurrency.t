use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

# Refresh-token reuse across callers sharing one stored session: the
# lost update of a DPoP nonce save writing stale tokens back, and two
# concurrent refreshes presenting the same refresh token. The mock auth
# server below rotates the refresh token on every use and rejects a
# replayed one with invalid_grant, as ATProto auth servers do. Same
# embedded-mock-app technique as t/resource_client.t (no real socket).

use Mojo::ATProto::OAuth                       qw//;
use Mojo::ATProto::OAuth::DPoP                  qw//;
use Mojo::ATProto::OAuth::ResourceClient       qw//;
use Mojo::ATProto::OAuth::SessionStore::Memory qw//;
use Mojo::ATProto::OAuth::SessionStore::SQLite qw//;
use Mojo::Promise;
use Mojolicious::Lite;
use Mojo::UserAgent;

# A store written against the original 12-method interface only - no
# update_session/lock_session - to exercise Mojo::ATProto::OAuth's
# fallback path for such stores.
package LegacyStore {
    use Mojo::Base -base, -signatures;
    has 'inner' => sub { Mojo::ATProto::OAuth::SessionStore::Memory->new };
    for my $method (qw/get_session get_session_p save_session save_session_p delete_session delete_session_p/) {
        no strict 'refs';
        *{$method} = sub ($self, @args) { return $self->inner->$method(@args) };
    }
}

sub session_fixture (%overrides) {
    return {
        account_did                => 'did:plc:testuser',
        session_id                 => 'session-1',
        handle                     => 'alice.example.com',
        host_url                   => '',
        auth_server_url            => 'https://auth.example.com',
        auth_server_token_endpoint => '/token',
        scopes                     => ['atproto'],
        access_token               => 'access-1',
        refresh_token              => 'refresh-1',
        dpop_authserver_nonce      => 'authserver-nonce-1',
        dpop_host_nonce            => 'host-nonce-1',
        dpop_private_key_pem       => Mojo::ATProto::OAuth::DPoP->export_private_pem(Mojo::ATProto::OAuth::DPoP->generate_keypair),
        %overrides,
    };
}

# Mock auth server + PDS in one app. /token rotates refresh-N to
# refresh-(N+1) / access-(N+1), rejecting anything but the current
# refresh token; with $state->{delay} set, a successful response is
# delayed that long so concurrent async requests really overlap (only
# for async callers - a blocking request doesn't run the singleton loop
# the delay timer lives on). $state->{on_replay}, if set, runs before a
# replay is rejected. The PDS route accepts only the current access
# token; $state->{on_pds_request}, if set, runs before it responds.
sub mock_servers () {
    my $state = {generation => 1, token_requests => [], pds_requests => 0};

    my $app = Mojolicious::Lite->new;
    $app->routes->post('/token' => sub ($c) {
        my $presented = $c->req->body_params->param('refresh_token') // '';
        push @{$state->{token_requests}}, $presented;
        if ($presented ne 'refresh-' . $state->{generation}) {
            $state->{on_replay}->() if $state->{on_replay};
            return $c->render(json => {error => 'invalid_grant'}, status => 400);
        }
        my $next    = ++$state->{generation};
        my $respond = sub {
            $c->res->headers->header('DPoP-Nonce' => "authserver-nonce-$next");
            $c->render(json => {access_token => "access-$next", refresh_token => "refresh-$next"});
        };
        return $respond->() unless $state->{delay};
        $c->render_later;
        Mojo::IOLoop->timer($state->{delay} => $respond);
    });
    $app->routes->get('/xrpc/app.bsky.actor.getProfile' => sub ($c) {
        $state->{pds_requests}++;
        $state->{on_pds_request}->($c) if $state->{on_pds_request};
        my ($token) = ($c->req->headers->header('Authorization') // '') =~ /^DPoP (.+)$/;
        return $c->render(json => {error => 'invalid_token'}, status => 401) unless ($token // '') eq 'access-' . $state->{generation};
        return $c->render(json => {ok => 1});
    });

    my $ua = Mojo::UserAgent->new;
    $ua->server->app($app);
    return ($ua, $state);
}

sub make_oauth ($store, $ua) {
    return Mojo::ATProto::OAuth->new(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        ua           => $ua,
        store        => $store,
    );
}

for my $store_class (qw/Memory SQLite/) {
    subtest "$store_class: concurrent refresh_tokens_p with the same refresh token refreshes once" => sub {
        my ($ua, $state) = mock_servers();
        $state->{delay} = 0.05;
        my $store = "Mojo::ATProto::OAuth::SessionStore::$store_class"->new;
        my $oauth = make_oauth($store, $ua);
        $store->save_session(session_fixture());

        my @refreshed;
        Mojo::Promise->all(
            $oauth->refresh_tokens_p($store->get_session('did:plc:testuser', 'session-1')),
            $oauth->refresh_tokens_p($store->get_session('did:plc:testuser', 'session-1')),
        )->then(sub (@all) { @refreshed = map { $_->[0] } @all })->wait;

        is($state->{token_requests}, ['refresh-1'], 'the auth server saw the refresh token exactly once');
        is([map { $_->{access_token} } @refreshed], ['access-2', 'access-2'], 'both callers ended up with the same new access token');
        my $stored = $store->get_session('did:plc:testuser', 'session-1');
        is([@{$stored}{qw/access_token refresh_token dpop_authserver_nonce/}], ['access-2', 'refresh-2', 'authserver-nonce-2'], 'the new tokens and nonce were persisted');
        is($stored->{dpop_host_nonce}, 'host-nonce-1', 'fields the refresh does not own were left alone');
    };
}

subtest 'refresh_tokens with a stale copy returns the already-refreshed row without calling the auth server' => sub {
    my ($ua, $state) = mock_servers();
    my $store = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $oauth = make_oauth($store, $ua);
    $store->save_session(session_fixture(access_token => 'access-2', refresh_token => 'refresh-2'));
    $state->{generation} = 2;

    my $stale    = session_fixture();
    my $returned = $oauth->refresh_tokens($stale);

    is($state->{token_requests}, [], 'no token request was made');
    ref_is($returned, $stale, 'the caller\'s own hashref is returned');
    is([@{$stale}{qw/access_token refresh_token/}], ['access-2', 'refresh-2'], 'and it was updated in place to the stored tokens');
};

subtest 'a store without update_session/lock_session still refreshes (fallback path)' => sub {
    my ($ua, $state) = mock_servers();
    my $store = LegacyStore->new;
    my $oauth = make_oauth($store, $ua);
    $store->save_session(session_fixture());

    my $refreshed = $oauth->refresh_tokens($store->get_session('did:plc:testuser', 'session-1'));
    is($refreshed->{access_token}, 'access-2', 'refreshed');
    is($store->get_session('did:plc:testuser', 'session-1')->{refresh_token}, 'refresh-2', 'persisted via save_session');

    my $refreshed_p;
    $oauth->refresh_tokens_p($store->get_session('did:plc:testuser', 'session-1'))->then(sub ($s) { $refreshed_p = $s })->wait;
    is($refreshed_p->{access_token}, 'access-3', 'refreshed asynchronously too');
    is($store->get_session('did:plc:testuser', 'session-1')->{refresh_token}, 'refresh-3', 'persisted via save_session_p');
};

subtest 'invalid_grant after another caller refreshed recovers by re-reading the row' => sub {
    my ($ua, $state) = mock_servers();
    my $store = LegacyStore->new;
    my $oauth = make_oauth($store, $ua);
    $store->save_session(session_fixture());

    # Simulates another process, with no lock to stop it, refreshing
    # between this caller's read and its token request.
    my $other_process = sub {
        $store->save_session({%{$store->get_session('did:plc:testuser', 'session-1')}, access_token => 'access-2', refresh_token => 'refresh-2'});
    };
    $state->{generation} = 2;
    $state->{on_replay}  = $other_process;

    my $refreshed = $oauth->refresh_tokens(session_fixture());
    is($refreshed->{access_token}, 'access-2', 'sync: the other caller\'s tokens were returned instead of dying');

    $store->save_session(session_fixture());
    my $refreshed_p;
    $oauth->refresh_tokens_p(session_fixture())->then(sub ($s) { $refreshed_p = $s })->wait;
    is($refreshed_p->{access_token}, 'access-2', 'async: same recovery');

    $store->save_session(session_fixture());
    $state->{on_replay} = undef;
    like(dies { $oauth->refresh_tokens(session_fixture()) }, qr/token refresh failed \(HTTP 400\): invalid_grant/, 'an invalid_grant with the row unchanged still dies');

    my $err;
    $oauth->refresh_tokens_p(session_fixture())->catch(sub ($e) { $err = $e })->wait;
    like($err, qr/token refresh failed \(HTTP 400\): invalid_grant/, 'and still rejects asynchronously');
};

subtest 'ResourceClient: a DPoP nonce save does not write back tokens refreshed elsewhere mid-request' => sub {
    for my $mode (qw/sync async/) {
        my ($ua, $state) = mock_servers();
        my $store  = Mojo::ATProto::OAuth::SessionStore::Memory->new;
        my $oauth  = make_oauth($store, $ua);
        my $client = Mojo::ATProto::OAuth::ResourceClient->new(oauth => $oauth);
        $store->save_session(session_fixture());

        # Another process refreshes while this request is in flight; the
        # response then rotates the host nonce.
        $state->{on_pds_request} = sub ($c) {
            $store->update_session('did:plc:testuser', 'session-1', {access_token => 'access-2', refresh_token => 'refresh-2'});
            $c->res->headers->header('DPoP-Nonce' => 'host-nonce-2');
        };

        if ($mode eq 'sync') {
            $client->request('did:plc:testuser', 'session-1', 'get', '/xrpc/app.bsky.actor.getProfile');
        } else {
            $client->request_p('did:plc:testuser', 'session-1', 'get', '/xrpc/app.bsky.actor.getProfile')->catch(sub { })->wait;
        }

        my $stored = $store->get_session('did:plc:testuser', 'session-1');
        is([@{$stored}{qw/access_token refresh_token dpop_host_nonce/}], ['access-2', 'refresh-2', 'host-nonce-2'], "$mode: new nonce saved, other caller's tokens kept");
    }
};

subtest 'ResourceClient: concurrent requests that both hit an expired access token refresh once' => sub {
    my ($ua, $state) = mock_servers();
    $state->{delay} = 0.05;
    my $store  = Mojo::ATProto::OAuth::SessionStore::Memory->new;
    my $oauth  = make_oauth($store, $ua);
    my $client = Mojo::ATProto::OAuth::ResourceClient->new(oauth => $oauth);
    $store->save_session(session_fixture(access_token => 'access-expired'));

    my @results;
    Mojo::Promise->all(
        $client->request_p('did:plc:testuser', 'session-1', 'get', '/xrpc/app.bsky.actor.getProfile'),
        $client->request_p('did:plc:testuser', 'session-1', 'get', '/xrpc/app.bsky.actor.getProfile'),
    )->then(sub (@all) { @results = map { $_->[0] } @all })->wait;

    is(\@results, [{ok => 1}, {ok => 1}], 'both requests succeeded');
    is($state->{token_requests}, ['refresh-1'], 'only one refresh reached the auth server');
    is($state->{pds_requests}, 4, 'each request was tried once, then retried once');
};

done_testing;
