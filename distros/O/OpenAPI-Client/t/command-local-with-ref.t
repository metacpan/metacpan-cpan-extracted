use lib '.';
use OpenAPI::Client;
use Test::More;

use Mojo::File 'path';

my $spec = path(qw(t spec with-ref.json))->to_abs;
plan skip_all => 'Cannot read spec' unless -r $spec;

use Mojolicious;
my $app = Mojolicious->new;
my $oc;
$app->plugin(OpenAPI => {spec => $spec});
$app->plugin(OpenAPI => {spec => path(qw(t spec with-external-ref.json))->to_abs});

$oc = eval { OpenAPI::Client->new('/api', app => $app) };
ok $oc, 'OpenAPI::Client loaded bundled spec' or diag $@;
ok !$oc->validator->schema->get('/definitions'), 'no definitions added';
ok $oc->validator->schema->get('/responses/error'), 'responses/error is still there';

$oc = eval { OpenAPI::Client->new('/ext', app => $app) };
ok $oc, 'OpenAPI::Client loaded bundled spec' or diag $@;

done_testing;
