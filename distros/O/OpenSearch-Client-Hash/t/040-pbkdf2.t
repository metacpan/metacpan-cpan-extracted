use Test::More;

BEGIN { use_ok('OpenSearch::Client::Hash') }

ok $h = OpenSearch::Client::Hash->new(), "new hash";

my $hash = $h->create_pbkdf2_password_hash( password => 'my test password') || '';

ok $hash, 'hash returned';
is( length($hash), 237, 'pbkdf2 hash-length' );
done_testing;
