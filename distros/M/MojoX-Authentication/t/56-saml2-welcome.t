use v5.24;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}
eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;
require TestSAML2;

# The welcome message uses "fullname" and falls back to the uid. With the
# default remaps, an IdP that sends no name claims must give the uid, not
# an empty name.

my $saml2 = TestSAML2->new;
my $mauth = MojoX::Authentication->new(model => { providers => [ $saml2 ] });
$mauth->app_startup(app);
app->log->level('fatal');

get  '/protected' => sub ($c) {
   my $message = $c->flash('message') // [ none => '' ];
   $c->render(text => $message->[1]);
} => 'protected_root';
get  '/saml2' => sub ($c) { $mauth->ctr_saml2_login($c, {}) };
post '/sso'   => sub ($c) { $mauth->ctr_saml2_sso_post($c) };

my $t = Test::Mojo->new;

sub welcome_for ($user) {
   $saml2->next_user($user);
   $t->get_ok('/saml2')->status_is(302);
   $t->post_ok('/sso', form => { SAMLResponse => 'whatever' })
     ->status_is(302)
     ->header_like(Location => qr{/protected\z}, 'login succeeds');
   return $t->get_ok('/protected')->tx->res->text;
}

is welcome_for({
      key => 'alice@example.com',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'
         => ['Alice'],
   }),
   'Welcome, Alice', 'name claims give the full name';

is welcome_for({ key => 'bob@example.com' }),
   'Welcome, bob@example.com', 'no name claims: fall back to the uid';

done_testing();
