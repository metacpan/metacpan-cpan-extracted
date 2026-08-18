use Test2::V0;

use Mojo::ATProto::OAuth::Identity qw//;

# Fixtures below are copied verbatim from indigo's own test suite
# (atproto/identity/testdata/*.json) - real DID documents, not
# invented shapes, so this is testing against the actual wire format
# rather than a guess at it.

my $resolver = Mojo::ATProto::OAuth::Identity->new;

subtest 'parse a modern did:plc document (Multikey verification method)' => sub {
    my $doc = {
        'id'                 => 'did:plc:ewvi7nxzyoun6zhxrhs64oiz',
        'alsoKnownAs'        => ['at://atproto.com'],
        'verificationMethod' => [
            {
                id                 => 'did:plc:ewvi7nxzyoun6zhxrhs64oiz#atproto',
                type               => 'Multikey',
                controller         => 'did:plc:ewvi7nxzyoun6zhxrhs64oiz',
                publicKeyMultibase => 'zQ3shXjHeiBuRCKmM36cuYnm7YEMzhGnCmCyW92sRJ9pribSF',
            },
        ],
        'service' => [
            {id => '#atproto_pds', type => 'AtprotoPersonalDataServer', serviceEndpoint => 'https://bsky.social'},
        ],
    };

    my $identity = $resolver->_parse_identity($doc);
    is($identity->{did}, 'did:plc:ewvi7nxzyoun6zhxrhs64oiz', 'did carried through');
    is($identity->{handle}, undef, '_parse_identity never sets handle - only a verified caller may');
    is($identity->{also_known_as}, ['at://atproto.com'], 'alsoKnownAs carried through');
    is($identity->{services}{atproto_pds}, {type => 'AtprotoPersonalDataServer', url => 'https://bsky.social'}, 'pds service extracted by fragment');
    is($identity->{keys}{atproto}, {type => 'Multikey', public_key_multibase => 'zQ3shXjHeiBuRCKmM36cuYnm7YEMzhGnCmCyW92sRJ9pribSF'}, 'key extracted by fragment, full-DID-prefixed id form');

    is($resolver->pds_endpoint($identity), 'https://bsky.social', 'pds_endpoint() extracts the same URL');
    is($resolver->_declared_handle($identity), 'atproto.com', 'declared handle parsed from at:// URI');
};

subtest 'parse a legacy did:plc document (bare-fragment verification method id)' => sub {
    my $doc = {
        'id'                 => 'did:plc:ewvi7nxzyoun6zhxrhs64oiz',
        'alsoKnownAs'        => ['at://atproto.com'],
        'verificationMethod' => [
            {
                id                 => '#atproto',
                type               => 'EcdsaSecp256k1VerificationKey2019',
                controller         => 'did:plc:ewvi7nxzyoun6zhxrhs64oiz',
                publicKeyMultibase => 'zQYEBzXeuTM9UR3rfvNag6L3RNAs5pQZyYPsomTsgQhsxLdEgCrPTLgFna8yqCnxPpNT7DBk6Ym3dgPKNu86vt9GR',
            },
        ],
        'service' => [
            {id => '#atproto_pds', type => 'AtprotoPersonalDataServer', serviceEndpoint => 'https://bsky.social'},
        ],
    };

    my $identity = $resolver->_parse_identity($doc);
    is($identity->{keys}{atproto}{type}, 'EcdsaSecp256k1VerificationKey2019', 'bare-fragment id form still keyed correctly');
};

subtest 'a key controlled by a different DID is excluded' => sub {
    my $doc = {
        id                 => 'did:plc:aaa',
        alsoKnownAs        => [],
        verificationMethod => [
            {id => '#atproto', type => 'Multikey', controller => 'did:plc:bbb', publicKeyMultibase => 'zSomeOtherKey'},
        ],
        service => [],
    };
    my $identity = $resolver->_parse_identity($doc);
    is($identity->{keys}, {}, 'key controlled by a different DID never makes it into the identity');
};

subtest 'first entry wins on a duplicate fragment id' => sub {
    my $doc = {
        id          => 'did:plc:aaa',
        alsoKnownAs => [],
        service     => [
            {id => '#atproto_pds', type => 'AtprotoPersonalDataServer', serviceEndpoint => 'https://first.example'},
            {id => '#atproto_pds', type => 'AtprotoPersonalDataServer', serviceEndpoint => 'https://second.example'},
        ],
    };
    my $identity = $resolver->_parse_identity($doc);
    is($identity->{services}{atproto_pds}{url}, 'https://first.example', 'duplicate fragment id does not clobber the first entry');
};

subtest 'a did:web document with no verification methods or declared handle' => sub {
    my $doc = {
        id                 => 'did:web:discover.bsky.social',
        alsoKnownAs        => [],
        verificationMethod => [],
        service            => [
            {id => '#bsky_fg', type => 'BskyFeedGenerator', serviceEndpoint => 'https://discover.bsky.social'},
        ],
    };
    my $identity = $resolver->_parse_identity($doc);
    is($identity->{keys}, {}, 'no keys');
    is($resolver->_declared_handle($identity), undef, 'no declared handle - alsoKnownAs is empty');
    is($resolver->pds_endpoint($identity), undef, 'no atproto_pds service on this document');
};

subtest 'declared handle: only the first at:// URI counts, non-at:// entries are ignored' => sub {
    my $identity = {also_known_as => ['https://example.com/not-a-handle', 'at://alice.example.com', 'at://ignored.example.com']};
    is($resolver->_declared_handle($identity), 'alice.example.com', 'first at:// URI wins, non-at:// entries skipped');
};

done_testing;
