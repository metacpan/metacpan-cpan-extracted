use strictures 2;

use Test::More;

use Net::Blossom::Server::AuthorizationResult;
use Net::Blossom::Server::Error;

my $PUBKEY = '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
my $SHA256 = '0f343b0931126a20f133d67c2b018a3b5ceca63dd3585a76cb1f3289a274707f';
my $OTHER_SHA256 = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

subtest 'constructs authorization result with copied hashes' => sub {
    my $hashes = [$SHA256];
    my $result = Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $PUBKEY,
        action => 'upload',
        hashes => $hashes,
    );

    isa_ok($result, 'Net::Blossom::Server::AuthorizationResult');
    is($result->pubkey, $PUBKEY, 'pubkey accessor');
    is($result->action, 'upload', 'action accessor');
    is_deeply($result->hashes, [$SHA256], 'hash accessor returns values');

    push @$hashes, $OTHER_SHA256;
    is_deeply($result->hashes, [$SHA256], 'constructor copies hashes');

    my $copy = $result->hashes;
    push @$copy, $OTHER_SHA256;
    is_deeply($result->hashes, [$SHA256], 'hash accessor does not alias');
};

subtest 'require_hash accepts authorized hashes and rejects mismatches' => sub {
    my $result = Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $PUBKEY,
        action => 'upload',
        hashes => [$SHA256],
    );

    ok($result->require_hash($SHA256), 'matching hash accepted');

    my $error = dies {
        $result->require_hash(
            $OTHER_SHA256,
            status => 409,
            reason => 'mirrored blob hash is not authorized',
        );
    };
    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 409, 'custom mismatch status');
    is($error->reason, 'mirrored blob hash is not authorized', 'custom mismatch reason');
    is($error->header('www-authenticate'), undef, 'non-401 mismatch does not challenge');
};

subtest 'require_hash defaults to authorization failure semantics' => sub {
    my $result = Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $PUBKEY,
        action => 'delete',
        hashes => [$SHA256],
    );

    my $error = dies { $result->require_hash($OTHER_SHA256) };
    isa_ok($error, 'Net::Blossom::Server::Error');
    is($error->status, 401, 'default mismatch status');
    is($error->header('www-authenticate'), 'Nostr', 'default mismatch challenges');
};

subtest 'validates constructor and method arguments' => sub {
    like(dies { Net::Blossom::Server::AuthorizationResult->new(action => 'get') },
        qr/pubkey is required/, 'pubkey required');
    like(dies { Net::Blossom::Server::AuthorizationResult->new(pubkey => 'A' x 64, action => 'get') },
        qr/pubkey must be 64-char lowercase hex/, 'pubkey format validated');
    like(dies { Net::Blossom::Server::AuthorizationResult->new(pubkey => $PUBKEY) },
        qr/action is required/, 'action required');
    like(dies { Net::Blossom::Server::AuthorizationResult->new(pubkey => $PUBKEY, action => []) },
        qr/action must be a scalar/, 'action scalar required');
    like(dies { Net::Blossom::Server::AuthorizationResult->new(pubkey => $PUBKEY, action => 'get', hashes => $SHA256) },
        qr/hashes must be an array reference/, 'hashes arrayref required');
    like(dies { Net::Blossom::Server::AuthorizationResult->new(pubkey => $PUBKEY, action => 'get', hashes => ['A' x 64]) },
        qr/hashes must contain 64-char lowercase hex values/, 'hash values validated');

    my $result = Net::Blossom::Server::AuthorizationResult->new(
        pubkey => $PUBKEY,
        action => 'get',
    );
    like(dies { $result->require_hash('A' x 64) },
        qr/sha256 must be 64-char lowercase hex/, 'required hash validated');
    like(dies { $result->require_hash($SHA256, status => 'bad') },
        qr/status must be an HTTP status code/, 'custom status validated');
    like(dies { $result->require_hash($SHA256, reason => []) },
        qr/reason must be a scalar/, 'custom reason validated');
};

done_testing;
