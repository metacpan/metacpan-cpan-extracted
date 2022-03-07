# t/004_gdpr_consent.t - display a page about cookies and GDPR
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::File qw(path tempdir);
use YAML::XS;

BEGIN {
  $ENV{MOJO_CONFIG} = path(__FILE__)->dirname->to_abs->child('slovo.conf');
};
note $ENV{MOJO_CONFIG};
my $install_root = tempdir('slovoXXXX', TMPDIR => 1, CLEANUP => 1);
my $t            = Test::Mojo->with_roles('+Slovo')->install(

# from => to
  undef() => $install_root,

# 0777
)->new('Slovo');
my $app = $t->app;

note $app->home;

# The _gdpr_consent celina must have been already inserted by the migrations mechanism.
# let's invoke the api endpoint which should give us $app->config->{consents}{gdpr_url}
my $json = $t->get_ok($app->url_for('/api/consents'))->status_is(200)
  ->json_is('/ihost' => '127.0.0.1')->tx->res->json;

note explain $json;
$t->get_ok($json->{gdpr_url})->status_is(200)
  ->text_like('section._consents p:first-child' => qr/^Щом/);

done_testing;
