#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::JSON;
use Mojo::File qw/path/;
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
my $url = $app->piwik->api('API.get' => {
  site_id => [4,5],
  urls => ['http://grimms-abenteuer.de/', 'http://khm.li/'],
  period => 'range',
  date => ['2012-11-01', '2012-12-01'],
  secure => 1,
  api_test => 1
});

like($url, qr{^/piwik-server/\?}, 'Piwik API 1');
like($url, qr{module=API}, 'Piwik API 2');
like($url, qr{method=API\.get}, 'Piwik API 3');
like($url, qr{format=JSON}, 'Piwik API 4');
like($url, qr{period=range}, 'Piwik API 5');
like($url, qr{date=2012-11-01.+?2012-12-01}, 'Piwik API 6');
like($url, qr{secure=1}, 'Piwik API 7');
like($url, qr{token_auth=anonymous}, 'Piwik API 8');
like($url, qr{urls%5B0%5D=http.+?grimms-abenteuer\.de}, 'Piwik API 9');
like($url, qr{urls%5B1%5D=http.+?khm\.li}, 'Piwik API 10');
like($url, qr{idSite=4.+?5}, 'Piwik API 11');

my $c = $app->build_controller;

like($c->piwik->api(
  'ExampleAPI.getPiwikVersion' => {
    %param
  }
)->{value}, qr{^[\.0-9]+$}, 'API.getPiwikVersion');

is($app->piwik->api(
  'ExampleAPI.getAnswerToLife' => {
    %param
  }
)->{value}, 42, 'API.getAnswerToLife');

is($app->piwik->api(
  'ExampleAPI.getObject' => {
    %param
  }
)->{result}, 'error', 'API.getObject');

is($app->piwik->api(
  'ExampleAPI.getSum' => {
    %param,
    a => 5,
    b => 7
  }
)->{value}, 12, 'API.getSum');

ok(!$app->piwik->api(
  'ExampleAPI.getNull' => {
    %param
  }
)->{value}, 'API.getNull');

my $array = $app->piwik->api(
  'ExampleAPI.getDescriptionArray' => {
    %param
  }
);

is($array->[0], 'piwik', 'API.getDescriptionArray 1');
like($array->[1], qr/open|free|libre/, 'API.getDescriptionArray 2');
is($array->[2], 'web analytics', 'API.getDescriptionArray 3');
is($array->[3], 'free', 'API.getDescriptionArray 4');
is($array->[4], 'Strong message: Свободный Тибет',
   'API.getDescriptionArray 5');

my $table = $app->piwik->api(
  'ExampleAPI.getCompetitionDatatable' => {
    %param
  }
);

is($table->[0]->{name}, 'piwik', 'API.getCompetitionDatatable 1');
is($table->[0]->{license}, 'GPL', 'API.getCompetitionDatatable 2');

is($table->[1]->{name}, 'google analytics', 'API.getCompetitionDatatable 3');
is($table->[1]->{license}, 'commercial', 'API.getCompetitionDatatable 4');

is($app->piwik->api(
  'ExampleAPI.getMoreInformationAnswerToLife' => {
    %param
  }
)->{value},
   'Check http://en.wikipedia.org/wiki/The_Answer_to_Life,_the_Universe,_and_Everything',
   'API.getMoreInformationAnswerToLife');

my $marray = $app->piwik->api(
  'ExampleAPI.getMultiArray' => {
    %param
  }
);

is($marray->{Limitation}->[0],
   'Multi dimensional arrays is only supported by format=JSON',
   'getMultiArray 1');

is($marray->{Limitation}->[1],
   'Known limitation',
   'getMultiArray 2');

my $sd = $marray->{'Second Dimension'};

is($sd->[0], Mojo::JSON->true, 'getMultiArray 3');
is($sd->[1], Mojo::JSON->false, 'getMultiArray 4');
is($sd->[2], 1, 'getMultiArray 5');
is($sd->[3], 0, 'getMultiArray 6');
is($sd->[4], 152, 'getMultiArray 7');
is($sd->[5], 'test', 'getMultiArray 8');
is($sd->[6]->{42}, 'end', 'getMultiArray 9');

done_testing;
