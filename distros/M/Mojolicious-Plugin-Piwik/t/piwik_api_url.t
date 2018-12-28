#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use Mojo::File qw/path/;
use Mojo::UserAgent;
use Data::Dumper;
use utf8;

#####################
# Start Fake server #
#####################
my $t = Test::Mojo->new;

# Mount mock Piwik instance
my $server_path = path(Mojo::File->new(__FILE__)->dirname, 'server');
my $fake_backend = $t->app->plugin(
  Mount => {
    '/piwik-server' =>
      $server_path->child('mock.pl')
    }
);

# Configure fake backend
$fake_backend->pattern->defaults->{app}->log($t->app->log);

my $app = $t->app;

my %param = (
  token_auth => 'xyz',
  site_id => 1
);

$app->mode('production');

# Use server
$app->plugin('Piwik' => {
  url => '/piwik-server/'
});


# API test
my $url = $app->piwik->api_url('API.get' => {
  site_id => [4,5],
  urls => ['https://grimms-abenteuer.de/', 'https://khm.li/'],
  period => 'range',
  date => ['2012-11-01', '2012-12-01'],
  secure => 1
});

like($url, qr{^/piwik-server\/\?}, 'Piwik API URL 1');
like($url, qr{module=API}, 'Piwik API URL 2');
like($url, qr{method=API\.get}, 'Piwik API URL 3');
like($url, qr{format=JSON}, 'Piwik API URL 4');
like($url, qr{period=range}, 'Piwik API URL 5');
like($url, qr{date=2012-11-01.+?2012-12-01}, 'Piwik API URL 6');
like($url, qr{secure=1}, 'Piwik API URL 7');
like($url, qr{token_auth=anonymous}, 'Piwik API URL 8');
like($url, qr{urls%5B0%5D=http.+?grimms-abenteuer\.de}, 'Piwik API URL 9');
like($url, qr{urls%5B1%5D=http.+?khm\.li}, 'Piwik API URL 10');
like($url, qr{idSite=4.+?5}, 'Piwik API URL 11');

ok($url = $app->piwik->api_url(
  'ExampleAPI.getPiwikVersion' => {
    %param
  }
), 'API.getPiwikVersion');

ok(my $ua = Mojo::UserAgent->new, 'New Mojo::UserAgent');
ok(my $json = $ua->get($url)->res->json, 'Get JSON');

like($json->{value}, qr{^[\.0-9]+$}, 'API.getPiwikVersion');

ok($url = $app->piwik->api_url(
  'ExampleAPI.getAnswerToLife' => {
    %param
  }
), 'API.getAnswerToLife');

ok($json = $ua->get($url)->res->json, 'Get JSON');
is($json->{value}, 42, 'API.getAnswerToLife');

ok($url = $app->piwik->api_url(
  'ExampleAPI.getObject' => {
    %param
  }
), 'API.getObject');

ok($json = $ua->get($url)->res->json, 'Get JSON');
is($json->{result}, 'error', 'API.getObject');

ok($url = $app->piwik->api_url(
  'ExampleAPI.getSum' => {
    %param,
    a => 5,
    b => 7
  }
), 'API.getSum');

ok($json = $ua->get($url)->res->json, 'Get JSON');
is($json->{value}, 12, 'API.getSum');

done_testing;
