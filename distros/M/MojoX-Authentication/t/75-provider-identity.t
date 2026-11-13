use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;
use FindBin qw< $Bin >;
use lib "$Bin/lib";

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}
eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 }
   or plan skip_all => 'Net::SAML2 0.86 not available';

use Mojolicious;
use MojoX::Authentication;
require TestSAML2;

# The same uid can exist in two providers. Whoever logged in through a
# provider must stay a user of *that* provider on the following requests,
# whatever the order of the providers.

sub make_app (@order) {
   my $saml2 = TestSAML2->new;
   my %provider_for = (
      saml2 => $saml2,
      hashy => {
         class => 'MojoX::Authentication::Model::Hash',
         args  => {
            db => { alice => { secret => 'pw', role => 'admin' } },
            secrets_are_cleartext => 1,
         },
      },
      other => {   # another local provider, a different "alice"
         class => 'MojoX::Authentication::Model::Hash',
         args  => {
            name => 'other',
            db => { alice => { secret => 'pw2' } },
            secrets_are_cleartext => 1,
         },
      },
   );
   my $mauth = MojoX::Authentication->new(
      model => { providers => [ @provider_for{@order} ] });

   my $app = Mojolicious->new;
   $app->log->level('fatal');
   $mauth->app_startup($app);
   my $r = $app->routes;
   $r->get('/public' => sub ($c) { $c->render(text => 'public') })
     ->name('public_root');
   $r->get('/protected' => sub ($c) {
      my $user = $c->current_user;
      $c->render(text => $user ? $user->{provider} : 'nobody');
   })->name('protected_root');
   $r->get('/saml2' => sub ($c) { $mauth->ctr_saml2_login($c, {}) });
   $r->post('/sso'  => sub ($c) { $mauth->ctr_saml2_sso_post($c) });
   $r->post('/login' => sub ($c) { $mauth->ctr_credentials_login($c) });
   $r->get('/token' => sub ($c) { $c->render(text => $c->csrf_token) });

   return (Test::Mojo->new($app), $saml2);
}

# login and logout need a CSRF token
sub token ($t) { $t->ua->get('/token')->result->text }

{
   # an IdP asserts NameID "alice", a local account "alice" exists too
   my ($t, $saml2) = make_app(qw< hashy saml2 >);
   $saml2->next_user({ key => 'alice' });
   $t->get_ok('/saml2')->status_is(302);
   $t->post_ok('/sso', form => { SAMLResponse => 'whatever' })
     ->status_is(302)
     ->header_like(Location => qr{/protected\z}, 'SAML2 login succeeds');
   $t->get_ok('/protected')
     ->content_is('saml2', 'SAML2 login stays a SAML2 user (local first)');
}

{
   # a SAML2 "alice" is cached, then someone logs in locally as "alice"
   # (local provider first: a default SAML2 first would own every name)
   my ($t, $saml2) = make_app(qw< hashy saml2 >);
   $saml2->_cache_user({ key => 'alice' });
   $t->post_ok('/login', form => { username => 'alice', password => 'pw',
      csrf_token => token($t) })
     ->status_is(302)
     ->header_like(Location => qr{/protected\z}, 'local login succeeds');
   $t->get_ok('/protected')
     ->content_is('hashy', 'local login stays a local user (SAML2 cached)');
}

{
   # a provider that knows the user but refuses the password ends the
   # login: later providers must not get a chance with the same username
   my ($t) = make_app(qw< hashy other >);
   $t->post_ok('/login', form => { username => 'alice', password => 'pw2',
      csrf_token => token($t) })
     ->status_is(302)
     ->header_like(Location => qr{/public\z},
        'wrong password for the first "alice" fails the login');
   $t->get_ok('/protected')->content_is('nobody', 'nobody is logged in');

   $t->post_ok('/login', form => { username => 'alice', password => 'pw',
      csrf_token => token($t) })
     ->status_is(302)
     ->header_like(Location => qr{/protected\z},
        'right password for the first "alice" works');
   $t->get_ok('/protected')->content_is('hashy', 'logged in as that "alice"');
}

done_testing();
