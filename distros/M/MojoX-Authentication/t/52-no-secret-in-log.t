use v5.24;
use warnings;
use Test::More;

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;

# Logs travel far (files, collectors, support tickets): a password login
# must not write the stored password hash, at any log level. The same goes
# for current_user, which ends up in the stash, templates and JSON.

my $mauth = MojoX::Authentication->new(
   model => {
      providers => [
         {
            class => 'MojoX::Authentication::Model::Hash',
            args  => { db => { foo => { secret => 'right' } },
                       secrets_are_cleartext => 1 },
         },
      ],
   },
);
$mauth->app_startup(app);

my @log;
app->log->level('trace');
app->log->unsubscribe('message');
app->log->on(message => sub ($log, $level, @lines) { push @log, @lines });

get  '/protected' => sub ($c) { $c->render(text => 'protected') }
   => 'protected_root';
get  '/me' => sub ($c) { $c->render(json => $c->current_user) };
get  '/token' => sub ($c) { $c->render(text => $c->csrf_token) };
post '/login' => sub ($c) { $mauth->ctr_credentials_login($c) };

my $t = Test::Mojo->new;
sub token { $t->ua->get('/token')->result->text }   # login and logout need it
$t->post_ok('/login', form => { username => 'foo', password => 'right',
   csrf_token => token() })
  ->status_is(302)
  ->header_like(Location => qr{/protected\z}, 'login succeeds');

my $hash = $mauth->model->provider_named('hashy')->db->{foo}{secret};
like $hash, qr{\A\$argon2}, 'stored secret is an Argon2 hash';
ok scalar(grep { m{login successful} } @log), 'the login was logged';
is_deeply [ grep { index($_, $hash) >= 0 } @log ], [],
   'no log line holds the password hash';

# current_user goes to the stash, templates, JSON: it must not carry the
# hash either, while the provider keeps it for checking passwords
my $me = $t->get_ok('/me')->status_is(200)->tx->res->json;
is $me && $me->{uid}, 'foo', 'current_user is the logged-in user';
unlike $t->tx->res->body, qr{\Q$hash\E}, 'current_user does not hold the hash';
is $mauth->model->provider_named('hashy')->load_user(undef, 'foo')->{secret},
   $hash, 'the provider still has the hash';

done_testing();
