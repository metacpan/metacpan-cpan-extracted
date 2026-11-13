use v5.24;
use warnings;
use Test::More;

for my $module (qw< Test::Mojo Mojolicious::Plugin::Authentication >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

use Mojolicious::Lite;
use experimental qw< signatures >;   # after Mojolicious::Lite, which re-enables its warning
use MojoX::Authentication;

# provider with its own logout, like SAML2
package WithLogout {
   sub new { bless { logged_out => 0 }, shift }
   sub name { 'with-logout' }
   sub handles_username ($self, $c, $name) { return $name eq 'foo' }
   sub validate_user ($self, $c, $name, $secret, $extra) {
      return $secret eq 'right' ? $name : undef;
   }
   sub load_user ($self, $c, $uid) { return { fullname => "User $uid" } }
   sub tamed_user_record ($self, $user) { return $user }
   sub logout ($self, $c, $user) { $self->{logged_out}++; $c->logout; return }
}

my $provider = WithLogout->new;
my $mauth = MojoX::Authentication->new(model => { providers => [ $provider ] });
$mauth->app_startup(app);

my @log;
app->log->level('info');
app->log->unsubscribe('message');   # no default output on STDERR
app->log->on(message => sub ($log, $level, @lines) { push @log, "@lines" });

get  '/public'    => sub ($c) { $c->render(text => 'public') }    => 'public_root';
get  '/protected' => sub ($c) { $c->render(text => 'protected') } => 'protected_root';
get  '/token'     => sub ($c) { $c->render(text => $c->csrf_token) };
post '/login'     => sub ($c) { $mauth->ctr_credentials_login($c) };
post '/logout'    => sub ($c) {
   $mauth->ctr_logout($c, 'public_root');
   $c->rendered(204) unless $c->res->code;  # make missing redirects visible
};
get  '/whoami'    => sub ($c) {
   $c->render(text => $c->is_user_authenticated ? 'in' : 'out');
};

my $t = Test::Mojo->new;
sub token { $t->ua->get('/token')->result->text }   # login and logout need it

$t->post_ok('/login', form => { username => 'foo', password => 'right',
   csrf_token => token() })
  ->status_is(302);
$t->get_ok('/whoami')->content_is('in', 'logged in');

@log = ();
$t->post_ok('/logout', form => { csrf_token => token() })
  ->status_is(302, 'provider logout still redirects')
  ->header_like(Location => qr{/public\z}, 'redirect goes to the requested route');
is $provider->{logged_out}, 1, "provider's own logout was called";
ok( (grep { m{logout: .*foo} } @log), 'logout log message names the user')
   or diag explain \@log;

$t->get_ok('/whoami')->content_is('out', 'logged out');

done_testing();
