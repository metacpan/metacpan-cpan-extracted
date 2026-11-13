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

# Usernames come from the login form and NameIDs from the IdP: logged
# verbatim, a newline in them forges log lines. No logged message may
# carry control characters.

my $forged = "\n[2026-01-01 00:00:00] [info] login successful (credentials): admin";
my $saml2  = TestSAML2->new(name => 'saml2');
my $mauth  = MojoX::Authentication->new(
   provider_name => 'saml2',
   model => {
      providers => [
         {
            class => 'MojoX::Authentication::Model::Hash',
            args  => { db => { "foo$forged" => { secret => 'right' } },
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
         $saml2,
      ],
   },
);
$mauth->app_startup(app);

my @log;
app->log->level('trace');
app->log->unsubscribe('message');
app->log->on(message => sub ($log, $level, @lines) { push @log, join ' ', @lines });

get  '/public'    => sub ($c) { $c->render(text => 'public') }    => 'public_root';
get  '/protected' => sub ($c) { $c->render(text => 'protected') } => 'protected_root';
get  '/token'     => sub ($c) { $c->render(text => $c->csrf_token) };
post '/login'     => sub ($c) { $mauth->ctr_credentials_login($c) };
post '/logout'    => sub ($c) { $mauth->ctr_logout($c, 'public_root') };
get  '/saml2'     => sub ($c) { $mauth->ctr_saml2_login($c, {}) };
post '/sso'       => sub ($c) { $mauth->ctr_saml2_sso_post($c) };

my $t = Test::Mojo->new;
sub token { $t->ua->get('/token')->result->text }   # login and logout need it

sub clean_log ($what) {
   is_deeply [ grep { m{[\x00-\x1f\x7f]} } @log ], [],
      "$what: no control characters in the log";
   @log = ();
}

$t->post_ok('/login', form => { username => "nobody$forged", password => 'x',
   csrf_token => token() })
  ->header_like(Location => qr{/public\z});
clean_log('failed credentials login');

$t->post_ok('/login', form => { username => "foo$forged", password => 'right',
   csrf_token => token() })
  ->header_like(Location => qr{/protected\z});
clean_log('successful credentials login');

$t->post_ok('/logout', form => { csrf_token => token() })
  ->header_like(Location => qr{/public\z});
clean_log('logout of a local user');

$saml2->next_user({ key => "alice$forged" });
$t->get_ok('/saml2')->status_is(302);
$t->post_ok('/sso', form => { SAMLResponse => 'whatever' })
  ->header_like(Location => qr{/protected\z});
clean_log('SAML2 login');

$t->post_ok('/logout', form => { csrf_token => token() })
  ->header_like(Location => qr{/public\z});
clean_log('logout of a SAML2 user');

done_testing();
