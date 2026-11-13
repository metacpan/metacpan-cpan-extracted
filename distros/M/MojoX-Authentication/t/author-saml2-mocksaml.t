
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use v5.24;
use warnings;
use experimental qw< signatures >;
use Test::More;
use FindBin qw< $Bin >;

# Full SAML2 round trip against the public mock IdP at https://mocksaml.com
# (no SP registration needed, any @example.com email logs in). Needs network
# access, so it only runs on request.
plan skip_all => 'set MOCKSAML=1 to run tests against https://mocksaml.com'
   unless $ENV{MOCKSAML};
eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

use Mojo::URL;
use Mojo::UserAgent;
use Mojolicious::Lite;
use Test::Mojo;
use MojoX::Authentication;

my $base     = 'https://mocksaml.com';
my $acs_url  = 'http://127.0.0.1:3000/saml2';   # never contacted, only echoed
my $email    = 'mojox-authn-test@example.com';

# fetched here and passed as XML: plain URLs go through LWP, whose default
# "libwww-perl/..." User-Agent gets a 403 from mocksaml.com
my $metadata = Mojo::UserAgent->new->get("$base/api/saml/metadata")->result;
plan skip_all => 'cannot get mocksaml metadata: ' . $metadata->code
   unless $metadata->is_success;

app->log->level('fatal');
app->secrets(['mocksaml-test']);

my $mauth = MojoX::Authentication->new(
   provider_name => 'saml2',
   model => {
      providers => [
         {
            name  => 'saml2',
            class => 'MojoX::Authentication::Model::SAML2',
            args  => {
               idp => $metadata->body,
               sp_configuration => {
                  identifier => 'https://srv.example.com/sp',
                  key        => "$Bin/../../eg/server.key",
                  'sso-post-url-override' => $acs_url,
               },
               remaps => [
                  sub ($r, $backwards) {
                     $r->{$_} = $r->{$_}[0] for qw< id email firstName lastName >;
                  },
               ],
            },
         },
      ],
   },
   -startup => app(),
);

get '/login' => sub ($c) { $mauth->ctr_saml2_login($c, { not_ok => 'failed' }) };
post '/saml2' => sub ($c) {
   $mauth->ctr_saml2_sso_post($c, { ok => 'me', not_ok => 'failed' });
};
get '/failed' => sub ($c) { $c->render(text => 'failed') } => 'failed';
get '/me' => sub ($c) {
   return $c->render(text => 'anonymous', status => 401)
      unless $c->is_user_authenticated;
   $c->render(json => $c->current_user);
} => 'me';
post '/logout' => sub ($c) { $mauth->ctr_logout($c, 'me') };
get  '/token'  => sub ($c) { $c->render(text => $c->csrf_token) };

my $t = Test::Mojo->new;
my $idp_ua = Mojo::UserAgent->new(max_redirects => 0);

# 1. our app sends the browser to the IdP with a signed AuthnRequest
$t->get_ok('/login')->status_is(302);
my $sso_url = Mojo::URL->new($t->tx->res->headers->location);
is $sso_url->host, 'mocksaml.com', 'redirected to mocksaml'
   or BAIL_OUT('no redirection to the IdP');
ok defined($sso_url->query->param('SAMLRequest')), 'redirect carries SAMLRequest';

# 2. the IdP accepts it and redirects to its login page
my $tx = $idp_ua->get($sso_url);
is $tx->res->code, 302, 'IdP accepts the AuthnRequest'
   or diag $tx->res->body;
my $login = Mojo::URL->new($tx->res->headers->location // '')->query;
is $login->param('acsUrl'), $acs_url, 'IdP got our ACS URL';
is $login->param('audience'), 'https://srv.example.com/sp', 'IdP got our entity ID';

# 3. "log in" at the IdP; it answers with an auto-POST form for our ACS
$tx = $idp_ua->post("$base/api/saml/auth" => form => {
   email    => $email,
   id       => $login->param('id'),
   audience => $login->param('audience'),
   acsUrl   => $login->param('acsUrl'),
});
is $tx->res->code, 200, 'IdP login succeeds' or diag $tx->res->body;
my $form = $tx->res->dom->at('form');
is $form && $form->attr('action'), $acs_url, 'IdP posts back to our ACS URL';
my $saml_response = $form && $form->at('input[name=SAMLResponse]');
ok $saml_response, 'IdP returns a SAMLResponse'
   or BAIL_OUT('no SAMLResponse from the IdP');

# 4. hand it to our app like the browser would
$t->post_ok('/saml2' => form => { SAMLResponse => $saml_response->val })
  ->status_is(302)->header_like(Location => qr{/me$}, 'assertion accepted');

$t->get_ok('/me')->status_is(200)
  ->json_is('/data/email', $email, 'email attribute, remapped to scalar')
  ->json_is('/data/firstName', 'mojox-authn-test', 'firstName attribute')
  ->json_like('/data/id', qr{\A[0-9a-f]{64}\z}, 'id attribute')
  ->json_is('/provider', 'saml2', 'user comes from the SAML2 provider');
my $uid = $t->tx->res->json('/uid');
ok defined($uid), "user has a uid ($uid)";

# 5. logout wipes the cached user
my $saml2 = $mauth->model->provider_named('saml2');
ok defined($saml2->load_user(undef, $uid)), 'user is cached';
$t->post_ok('/logout',
   form => { csrf_token => $t->ua->get('/token')->result->text })->status_is(302);
$t->get_ok('/me')->status_is(401, 'logged out');
ok !defined($saml2->load_user(undef, $uid)), 'cached user wiped at logout';

# the same response cannot be used twice, even with the saml-id cookie
# still around and within request_ttl: request ids are single use
$t->post_ok('/saml2' => form => { SAMLResponse => $saml_response->val })
  ->status_is(302)->header_like(Location => qr{/failed$}, 'replay rejected');

done_testing();
