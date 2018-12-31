use Test::More;
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' };
use Test::Mojo;
use Data::Dumper;
use Mojo::File qw/path/;
use Mojolicious::Lite;
use Mojo::IOLoop;

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

$t->app->mode('production');

# Use server
$t->app->plugin('Piwik' => {
  url => '/piwik-server/'
});

my $c = $t->app->build_controller;

my %param = (
  token_auth => 'xyz',
  site_id => 1
);

my $result;
$c->piwik->api_p(Track => {
  site_id => 1,
  action_url => 'https://sojolicio.us',
  action_name => 'Test'
})->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is('', $result->{body}, 'Track');


$c->piwik->api_p(
  'ExampleAPI.getPiwikVersion' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

like($result->{value}, qr{^[\.0-9]+$}, 'API.getPiwikVersion');


$c->piwik->api_p(
  'ExampleAPI.getAnswerToLife' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->{value}, 42, 'API.getAnswerToLife');

$c->piwik->api_p(
  'ExampleAPI.getObject' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->{result}, 'error', 'API.getObject');

$c->piwik->api_p(
  'ExampleAPI.getSum' => {
    %param,
    a => 5,
    b => 7
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->{value}, 12, 'API.getSum');


$c->piwik->api_p(
  'ExampleAPI.getNull' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

ok(!($result->{value}), 'API.getNull');


$c->piwik->api_p(
  'ExampleAPI.getDescriptionArray' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->[0], 'piwik', 'API.getDescriptionArray 1');
like($result->[1], qr/open|free|libre/, 'API.getDescriptionArray 2');
is($result->[2], 'web analytics', 'API.getDescriptionArray 3');
is($result->[3], 'free', 'API.getDescriptionArray 4');
is($result->[4], 'Strong message: Свободный Тибет',
   'API.getDescriptionArray 5');


$c->piwik->api_p(
  'ExampleAPI.getCompetitionDatatable' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->[0]->{name}, 'piwik', 'API.getCompetitionDatatable 1');
is($result->[0]->{license}, 'GPL', 'API.getCompetitionDatatable 2');
is($result->[1]->{name}, 'google analytics', 'API.getCompetitionDatatable 3');
is($result->[1]->{license}, 'commercial', 'API.getCompetitionDatatable 4');


$c->piwik->api_p(
  'ExampleAPI.getMoreInformationAnswerToLife' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->{value},
   'Check http://en.wikipedia.org/wiki/The_Answer_to_Life,_the_Universe,_and_Everything',
   'API.getMoreInformationAnswerToLife');

$c->piwik->api_p(
  'ExampleAPI.getMultiArray' => {
    %param
  }
)->then(sub { $result = shift })->wait;

Mojo::IOLoop->one_tick;

is($result->{Limitation}->[0],
   'Multi dimensional arrays is only supported by format=JSON',
   'getMultiArray 1');

is($result->{Limitation}->[1],
   'Known limitation',
   'getMultiArray 2');

my $sd = $result->{'Second Dimension'};

is($sd->[0], Mojo::JSON->true, 'getMultiArray 3');
is($sd->[1], Mojo::JSON->false, 'getMultiArray 4');
is($sd->[2], 1, 'getMultiArray 5');
is($sd->[3], 0, 'getMultiArray 6');
is($sd->[4], 152, 'getMultiArray 7');
is($sd->[5], 'test', 'getMultiArray 8');
is($sd->[6]->{42}, 'end', 'getMultiArray 9');

done_testing;
__END__
