use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

my $app = make_app();
my $t   = Test::Mojo->new($app);

$t->get_ok('/test/foo')->status_is(404);
$t->get_ok('/test/bar')->status_is(200)->content_is('ok');

done_testing;

sub make_app {
  return eval <<'HERE' || die $@;
package MyApp;
use Mojo::Base "Mojolicious";
sub startup {
  my $app = shift;
  $app->routes->get("/:controller/:action");
  $app->helper(foo => sub { die "do not route here" });
  $app->plugin("FastHelpers");
}

package MyApp::Controller::Test;
use Mojo::Base "Mojolicious::Controller";
sub bar { shift->render(text => "ok") }

MyApp->new;
HERE
}
