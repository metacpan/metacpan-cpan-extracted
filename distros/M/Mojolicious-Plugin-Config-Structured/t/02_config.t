use v5.22;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

$ENV{MOJO_MODE} = 'test';
$ENV{MOJO_HOME} = "./t/conf";
app->home->detect;
app->log->path('/dev/null');    #suppress logged messages for testing cleanliness

ok(dies {plugin 'Config::Structured'}, 'no structure');

app->moniker("TestApp");
ok(lives {plugin 'Config::Structured'}, 'empty config');
ok(app->conf,                           'try to access conf method');
is(app->conf->db->user, undef, 'confirm conf not loaded');

app->moniker("TestApp2");
plugin 'Config::Structured';
is(app->conf->db->user, 'tyrrminal', 'check config loaded');

plugin 'Config::Structured' => {
  structure_file => 't/conf/structure.yml',
  config_file    => 't/conf/config.yml'
};
is(app->conf->email->smtp->host, 'mail.site.com', 'check param passing and priority');

done_testing;
