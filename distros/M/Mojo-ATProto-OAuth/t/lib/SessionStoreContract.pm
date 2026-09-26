package SessionStoreContract;
use Mojo::Base -strict, -signatures;

use Test2::V0;
use Mojo::Promise qw//;
use Exporter      qw/import/;

our @EXPORT_OK = qw/update_and_lock_subtests/;

# Runs the update_session(_p) / lock_session(_p) contract checks shared by
# every shipped store. $make_store returns a fresh, empty store;
# $make_session returns a full session hashref (the SQL stores enforce
# NOT NULL on the documented always-present fields) that can be varied
# with %overrides.
sub update_and_lock_subtests($make_store, $make_session) {
    subtest 'update_session writes only the given fields' => sub {
        my $store   = $make_store->();
        my $session = $make_session->();
        $store->save_session($session);

        $store->update_session($session->{account_did}, $session->{session_id}, {dpop_host_nonce => 'nonce-new'});
        is($store->get_session($session->{account_did}, $session->{session_id}), {%$session, dpop_host_nonce => 'nonce-new'}, 'only dpop_host_nonce changed');

        $store->update_session_p($session->{account_did}, $session->{session_id}, {access_token => 'tok-new', refresh_token => 'ref-new'})->wait;
        my $fetched = $store->get_session($session->{account_did}, $session->{session_id});
        is([@{$fetched}{qw/access_token refresh_token dpop_host_nonce/}], ['tok-new', 'ref-new', 'nonce-new'], 'update_session_p changed the tokens and kept the earlier nonce');
    };

    subtest 'update_session rejects bad input and misses' => sub {
        my $store   = $make_store->();
        my $session = $make_session->();
        $store->save_session($session);
        my @key = ($session->{account_did}, $session->{session_id});

        like(dies { $store->update_session(@key, {scopes => ['atproto']}) }, qr/field 'scopes' cannot be updated/, 'a field outside the allowed set dies');
        like(dies { $store->update_session(@key, {}) },                      qr/non-empty hashref/,                  'an empty update dies');
        like(dies { $store->update_session(@key, undef) },                   qr/non-empty hashref/,                  'a non-hashref dies');
        like(dies { $store->update_session($key[0], 'nonexistent', {access_token => 'x'}) }, qr/no session found/, 'a miss dies with the usual message');
        is($store->get_session(@key), $session, 'nothing was written by the rejected calls');

        my $err;
        $store->update_session_p($key[0], 'nonexistent', {access_token => 'x'})->catch(sub ($e) { $err = $e })->wait;
        like($err, qr/no session found/, 'update_session_p rejects on a miss');
    };

    subtest 'lock_session runs the code with a fresh read and returns its result' => sub {
        my $store   = $make_store->();
        my $session = $make_session->();
        $store->save_session($session);

        my $result = $store->lock_session($session->{account_did}, $session->{session_id}, sub ($current) {
            return 'saw ' . $current->{refresh_token};
        });
        is($result, 'saw ' . $session->{refresh_token}, 'result passed through');

        like(dies { $store->lock_session($session->{account_did}, $session->{session_id}, sub ($current) { die "inner failure\n" }) }, qr/^inner failure$/, 'an exception from the code propagates');
        is($store->lock_session($session->{account_did}, $session->{session_id}, sub ($current) { return 'again' }), 'again', 'and the lock was released afterwards');
        like(dies { $store->lock_session($session->{account_did}, 'nonexistent', sub ($current) { return 1 }) }, qr/no session found/, 'a miss dies with the usual message');
    };

    subtest 'lock_session_p serializes callers on the same session' => sub {
        my $store   = $make_store->();
        my $session = $make_session->();
        $store->save_session($session);
        my @key = ($session->{account_did}, $session->{session_id});

        my @events;
        my $worker = sub ($name) {
            return sub ($current) {
                push @events, "enter $name saw $current->{refresh_token}";
                return $store->update_session_p(@key, {refresh_token => "ref-$name"})
                    ->then(sub { return Mojo::Promise->timer(0.05) })
                    ->then(sub { push @events, "exit $name"; return $name });
            };
        };

        my @results;
        Mojo::Promise->all(
            $store->lock_session_p(@key, $worker->('a')),
            $store->lock_session_p(@key, $worker->('b')),
        )->then(sub (@all) { @results = map { $_->[0] } @all })->wait;

        is(\@events, ['enter a saw ' . $session->{refresh_token}, 'exit a', 'enter b saw ref-a', 'exit b'], 'the second caller waited for the first, then saw what it wrote');
        is(\@results, ['a', 'b'], 'each caller got its own code\'s result');
    };

    subtest 'lock_session_p releases the lock when the code fails' => sub {
        my $store   = $make_store->();
        my $session = $make_session->();
        $store->save_session($session);
        my @key = ($session->{account_did}, $session->{session_id});

        my ($err, $second);
        Mojo::Promise->all_settled(
            $store->lock_session_p(@key, sub ($current) { die "inner failure\n" })->catch(sub ($e) { $err = $e }),
            $store->lock_session_p(@key, sub ($current) { return 'ran' })->then(sub ($r) { $second = $r }),
        )->wait;

        is($err,    "inner failure\n", 'the failing caller rejected with its own error');
        is($second, 'ran',             'the next caller still got the lock');
    };

    subtest 'lock_session_p does not serialize different sessions' => sub {
        my $store = $make_store->();
        my $one   = $make_session->();
        my $two   = $make_session->(session_id => 'other-session');
        $store->save_session($_) for ($one, $two);

        my @events;
        my $worker = sub ($name) {
            return sub ($current) {
                push @events, "enter $name";
                return Mojo::Promise->timer(0.05)->then(sub { push @events, "exit $name" });
            };
        };
        Mojo::Promise->all(
            $store->lock_session_p($one->{account_did}, $one->{session_id}, $worker->('one')),
            $store->lock_session_p($two->{account_did}, $two->{session_id}, $worker->('two')),
        )->wait;

        is([@events[0, 1]], ['enter one', 'enter two'], 'both entered before either finished');
    };
}

1;
