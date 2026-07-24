use Test::More;

BEGIN { use_ok('OpenSearch::Client::Hash') }

ok $h = OpenSearch::Client::Hash->new(), "new hash";

for my $method ( qw( create_bcrypt_password_hash create_argon2_password_hash create_pbkdf2_password_hash  ) ) {
    ok $h->can($method), qq(can $method);
}

done_testing;

