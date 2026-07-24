use Test::More;

BEGIN { use_ok('OpenSearch::Client::Hash') }

ok $h = OpenSearch::Client::Hash->new(), "new hash";

for my $type ( qw( argon2id argon2i argon2d ) ) {
    my $hash = $h->create_argon2_password_hash( password => 'my test password', type => $type);
    ok $hash, $type . ' hash returned';
    my $expected_len = 110 + length($type);
    is( length($hash), $expected_len, $type . ' hash-length' );
}

done_testing;
