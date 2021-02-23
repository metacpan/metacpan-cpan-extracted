use lib '.';
use Mojo::File 'path';
use Mojolicious;
use OpenAPI::Client;
use Test::More;

my $spec = path(qw(t spec with-ref.json))->to_abs;
plan skip_all => 'Cannot read spec' unless -r $spec;

eval {
  my $app = Mojolicious->new;
  my $oc;

  $app->routes->get(sub { my $c = shift }, 'dummy');
  $app->plugin(OpenAPI => {default_response_codes => [], spec => $spec});
  $app->plugin(OpenAPI => {default_response_codes => [], spec => path(qw(t spec with-external-ref.json))->to_abs});

  $oc = OpenAPI::Client->new('/api', app => $app);
  ok $oc, 'OpenAPI::Client loaded bundled spec' or diag $@;
  ok $oc->validator->get('/responses/error'), 'responses/error is still there';

  $oc = OpenAPI::Client->new('/ext', app => $app);
  ok $oc, 'OpenAPI::Client loaded bundled spec' or diag $@;
} or do {

  # Getting "Service Unavailable" from some of the cpantesters
  plan skip_all => $@;
};

done_testing;
