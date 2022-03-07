# t/005_footer_right.t
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
my $phone = $app->config->{consents}{phone_url};
$t->get_ok($app->config->{consents}{gdpr_url})->status_is(200)

# In a regular browser like Firefox, the function set_gdpr_consent from cart.js
# replaces the content on all pages except gdpr_consent_url with
# gdpr_consent_template, unless the user had visited gdpr_consent_url.
  ->text_like('footer.is-fixed .social a.sharer:first-child' => qr/\Q$phone\E/);


done_testing;
