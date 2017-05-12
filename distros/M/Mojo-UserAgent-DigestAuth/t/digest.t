use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojo::UserAgent::DigestAuth;

# This test use testdata from http://en.wikipedia.org/wiki/Digest_access_authentication

ok $main::_request_with_digest_auth, 'request_with_digest_auth';

{
  my %expected = (
    username => 'Mufasa',
    realm    => 'testrealm@host.com',
    nonce    => 'dcd98b7102dd2f0e8b11d0f600bfb0c093',
    uri      => '/dir/index.html',
    qop      => 'auth',
    nc       => '00000001',
    cnonce   => '0a4f113b',
    response => '6629fae49393a05397450978507c4ef1',
    opaque   => '5ccc069c403ebaf9f0171e9517f40e41',
  );

  my $authenticate = sub {
    my $c = shift;
    $c->res->headers->header('WWW-Authenticate' =>
        'Digest realm="testrealm@host.com", qop="auth,auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", opaque="5ccc069c403ebaf9f0171e9517f40e41"'
    );
    $c->render(text => 'missing authorization', status => 401);
  };

  use Mojolicious::Lite;
  get '/plain' => sub { shift->render(text => 'no-auth-needed') };
  get '/dir/index' => sub {
    my $c      = shift;
    my $header = $c->req->headers->authorization;
    return $c->$authenticate unless $header;
    my %auth_param = $header =~ /(\w+)="?([^",]+)"?/g;
    my $invalid = join ' ', grep { $auth_param{$_} ne $expected{$_} } sort keys %expected;
    $c->res->headers->header('D-Client-Nonce' => $c->req->headers->header('D-Client-Nonce') || 'undef');
    return $c->render(text => $invalid, status => 403) if $invalid;
    return $c->render(text => 'success');
  };
}

my $t   = Test::Mojo->new;
my $url = Mojo::URL->new('/dir/index.html')->userinfo('Mufasa:Circle Of Life');

$t->get_ok('/plain')->status_is(200)->content_is('no-auth-needed');
$t->get_ok('/dir/index.html')->status_is(401)->content_is('missing authorization');

my $tx = $t->ua->$_request_with_digest_auth(get => '/dir/index.html');
$t->tx($tx)->status_is(401)->content_is('missing authorization');

$t->tx($t->ua->$_request_with_digest_auth(get => $url, { 'D-Client-Nonce' => '0a4f113b' }))->status_is(200)->header_is('D-Client-Nonce', 'undef')->content_is('success', 'success');

$t->tx($t->ua->$_request_with_digest_auth(get => $url))->status_is(403)->header_is('D-Client-Nonce', 'undef')->content_is('cnonce nc response');

done_testing;
