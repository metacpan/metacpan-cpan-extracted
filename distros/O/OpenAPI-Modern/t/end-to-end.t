# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use 5.020;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use JSON::Schema::Modern::Utilities 'jsonp';
use Mojolicious;
use Test::Mojo;

use lib 't/lib';
use Helper;

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');
my $doc_uri_rel = Mojo::URL->new('/api');
my $doc_uri = $doc_uri_rel->to_abs(Mojo::URL->new('http://example.com'));

subtest 'full end-to-end test of transmitted request and response' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri_rel,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /foo/{foo_id}:
    parameters:
    - name: foo_id
      in: path
      required: true
      schema:
        pattern: ^[a-z]+$
    post:
      requestBody:
        required: true
        content:
          application/json:
            schema:
              additionalProperties:
                type: integer
                minimum: 3
      responses:
        default:
          description: success
          content:
            application/json:
              schema:
                type: object
                required: [ status ]
                properties:
                  status:
                    const: ok
YAML

  my $app = Mojolicious->new;
  $app->routes->post('/foo/:foo_id' => sub ($c) {
    if ($c->stash('foo_id') =~ /^[a-z]+$/) {
      cmp_result(
        $openapi->validate_request($c->req)->TO_JSON,
        { valid => true },
        'a valid request is received',
      );
      return $c->render(json => { status => 'ok' });
    }
    else {
      my $host = $c->req->headers->host;

      cmp_result(
        $openapi->validate_request($c->req)->TO_JSON,
        {
          valid => false,
          errors => [
            {
              instanceLocation => '/request/uri/path/foo_id',
              keywordLocation => jsonp(qw(/paths /foo/{foo_id} parameters 0 schema pattern)),
              absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} parameters 0 schema pattern)))->to_string,
              error => 'pattern does not match',
            },
            {
              instanceLocation => '/request',
              keywordLocation => jsonp(qw(/paths /foo/{foo_id} post requestBody required)),
              absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post requestBody required)))->to_string,
              error => 'request body is required but missing',
            },
          ],
        },
        'an invalid request is received',
      );
      return $c->render(json => { status => 'not ok' }, status => 400);
    }
  });

  my $t = Test::Mojo->new($app);

  $t->post_ok('/foo/hello', json => {})
    ->status_is(200)
    ->json_is('/status', 'ok');

  cmp_result(
    $openapi->validate_response($t->tx->res, { request => $t->tx->req })->TO_JSON,
    { valid => true },
    '...and results in a valid 200 response',
  );

  $t->post_ok('/foo/123')
    ->status_is(400)
    ->json_is('/status', 'not ok');

  cmp_result(
    $openapi->validate_response($t->tx->res, { request => $t->tx->req })->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/response/body/status',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post responses default content application/json schema properties status const)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post responses default content application/json schema properties status const)))->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/response/body',
          keywordLocation => jsonp(qw(/paths /foo/{foo_id} post responses default content application/json schema properties)),
          absoluteKeywordLocation => $doc_uri_rel->clone->fragment(jsonp(qw(/paths /foo/{foo_id} post responses default content application/json schema properties)))->to_string,
          error => 'not all properties are valid',
        },
      ],
    },
    '...and results in an invalid 400 response',
  );
};

done_testing;
