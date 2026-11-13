use v5.24;
use warnings;
use Test::More;

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;

# stand-in for a SAML2 provider, only idp_login is needed here
package FakeSAML2 {
   sub new { bless {}, shift }
   sub name { 'fake-saml2' }
   sub idp_login { return ('fake-id', 'http://idp.example.com/sso') }
}

my $mauth = MojoX::Authentication->new(
   provider_name => 'fake-saml2',
   model => {
      providers => [
         {
            class => 'MojoX::Authentication::Model::Hash',
            args  => { db => { foo => { secret => 'right' } },
                       secrets_are_cleartext => 1 },
         },
         FakeSAML2->new,
      ],
   },
);
$mauth->app_startup(app);

get  '/public'    => sub ($c) { $c->render(text => 'public') }    => 'public_root';
get  '/protected' => sub ($c) { $c->render(text => 'protected') } => 'protected_root';
post '/login'     => sub ($c) { $mauth->ctr_credentials_login($c) };
get  '/saml2'     => sub ($c) { $mauth->ctr_saml2_login($c, {}) };

my $t = Test::Mojo->new;

$t->post_ok('/login', form => { username => 'foo', password => 'wrong' })
  ->status_is(302)
  ->header_like(Location => qr{/public\z}, 'failed login goes to public_root by default');

$t->get_ok('/saml2')
  ->status_is(302)
  ->header_is(Location => 'http://idp.example.com/sso',
     'provider_name set in the object selects the provider');

done_testing();
