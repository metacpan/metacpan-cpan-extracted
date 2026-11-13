use v5.24;
use warnings;
use Test::More;

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;

# Login and logout change who the browser is logged in as: a hostile page
# must not be able to do either with an auto-submitted form. Both need
# Mojolicious' csrf_token (session-bound) in the form.

my $mauth = MojoX::Authentication->new(
   model => {
      providers => [
         {
            class => 'MojoX::Authentication::Model::Hash',
            args  => { db => { foo => { secret => 'right' } },
                       secrets_are_cleartext => 1,
                       # Argon2 at its minimum (8 KiB, one pass): this test
                       # is not about the cost of password checks, and the
                       # default (256 MiB, three passes) is slow enough on
                       # small testers to hit the test server's 30 s
                       # inactivity timeout. Timing guarantees are tested in
                       # t/34, which counts password checks instead.
                       crypt_passphrase => { encoder => { module => q<Argon2>,
                          memory_cost => q<8k>, time_cost => 1 } } },
         },
      ],
   },
);
$mauth->app_startup(app);
app->log->level('fatal');

get  '/public'    => sub ($c) { $c->render(text => 'public') }    => 'public_root';
get  '/protected' => sub ($c) { $c->render(text => 'protected') } => 'protected_root';
get  '/token'     => sub ($c) { $c->render(text => $c->csrf_token) };
get  '/whoami'    => sub ($c) {
   $c->render(text => $c->is_user_authenticated ? $c->current_user->{uid} : '');
};
post '/login'     => sub ($c) { $mauth->ctr_credentials_login($c) };
post '/logout'    => sub ($c) { $mauth->ctr_logout($c, 'public_root') };

my $t = Test::Mojo->new;
my $creds = { username => 'foo', password => 'right' };
sub whoami { $t->get_ok('/whoami')->tx->res->text }

# login CSRF: the attacker's page posts the attacker's own credentials
$t->post_ok('/login', form => $creds)->status_is(302)
  ->header_like(Location => qr{/public\z}, 'login without token goes to public');
is whoami(), '', 'login without token: not logged in';

$t->post_ok('/login', form => { %$creds, csrf_token => 'forged' })->status_is(302);
is whoami(), '', 'login with a wrong token: not logged in';

my $token = $t->get_ok('/token')->tx->res->text;
$t->post_ok('/login', form => { %$creds, csrf_token => $token })
  ->status_is(302)
  ->header_like(Location => qr{/protected\z}, 'login with the token succeeds');
is whoami(), 'foo', 'login with the token: logged in';

# logout CSRF
$t->post_ok('/logout')->status_is(302);
is whoami(), 'foo', 'logout without token: still logged in';

$token = $t->get_ok('/token')->tx->res->text;
$t->post_ok('/logout', form => { csrf_token => $token })->status_is(302);
is whoami(), '', 'logout with the token: logged out';

done_testing();
