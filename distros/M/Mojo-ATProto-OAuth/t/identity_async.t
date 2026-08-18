use Test2::V0;
use feature 'signatures';
no warnings 'experimental::signatures';

use Mojo::ATProto::OAuth::Identity qw//;
use Mojo::Promise;
use Mojo::IOLoop;

# The transport-level correctness of the _p methods (resolve_handle_dns_p's
# real bgsend/bgread-via-reactor mechanism, and the HTTP _p methods'
# real network calls) was verified live against real ATProto
# infrastructure (bsky.app) rather than mocked here - see this commit's
# message for the transcript. What's covered here, without a live
# network dependency: the pure promise-wiring/dispatch logic that
# doesn't require real I/O to exercise.

my $resolver = Mojo::ATProto::OAuth::Identity->new;

subtest 'resolve_did_p rejects immediately for an unsupported DID method, no I/O attempted' => sub {
    my $err;
    $resolver->resolve_did_p('did:example:whatever')->catch(sub ($e) { $err = $e })->wait;
    like($err, qr/unsupported DID method/, 'promise rejected with the expected message');
};

subtest 'resolve_handle_dns_p resolves to undef (not an error) when bgsend itself fails to produce a socket' => sub {
    # A DNS resolver with no reachable nameserver at all still returns
    # *something* from bgsend in practice; this exercises the "no
    # socket" branch directly instead, since that's the one path that
    # doesn't touch the network at all.
    my $id = Mojo::ATProto::OAuth::Identity->new;

    # Net::DNS::Resolver->bgsend returns a false value on outright
    # construction failure (e.g. a malformed query) - simulate that
    # directly rather than trying to fake a whole resolver object.
    no warnings 'redefine', 'once';
    local *Net::DNS::Resolver::bgsend = sub { return undef };

    my $result;
    $id->resolve_handle_dns_p('example.com')->then(sub ($did) { $result = $did })->wait;
    is($result, undef, 'resolves to undef rather than hanging or dying when bgsend produces no socket');
};

subtest '_lookup_did_p treats a resolve_handle_p rejection as "could not verify", not a lookup failure' => sub {
    my $id = Mojo::ATProto::OAuth::Identity->new;

    no warnings 'redefine';
    local *Mojo::ATProto::OAuth::Identity::resolve_did_p = sub ($self, $did) {
        return Mojo::Promise->resolve({
            id          => $did,
            alsoKnownAs => ['at://alice.example.com'],
        });
    };
    local *Mojo::ATProto::OAuth::Identity::resolve_handle_p = sub ($self, $handle) {
        return Mojo::Promise->reject("could not resolve handle '$handle' to a DID (DNS and HTTP well-known both failed)\n");
    };

    my $identity;
    $id->lookup_p('did:plc:aaa')->then(sub ($i) { $identity = $i })->wait;
    is($identity->{did}, 'did:plc:aaa', 'lookup still resolves');
    is($identity->{handle}, undef, 'handle stays unverified rather than failing the whole lookup');
};

done_testing;
