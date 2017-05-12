use Mojo::Base -strict;
use Test::More;
use Mojo::UserAgent::DigestAuth;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

my $ua = Mojo::UserAgent->new;

my $tx = $ua->$_request_with_digest_auth(get => 'http://user:passwd@httpbin.org/digest-auth/auth/batman/invalidpw');
is $tx->res->code, 401, 'batman:invalidpw';

my $cookie = $tx->res->headers->set_cookie;
ok $cookie, 'set_cookie';

$tx = $ua->$_request_with_digest_auth(
  get => 'http://user:passwd@httpbin.org/digest-auth/auth/user/passwd',
  {Cookie => $cookie}
);
is $tx->res->code, 200, 'user:passwd';

done_testing;
