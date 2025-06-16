# vim: set ts=8 sts=2 sw=2 tw=100 et :
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
no if "$]" >= 5.041009, feature => 'smartmatch';
no feature 'switch';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use JSON::Schema::Modern::Utilities 'jsonp';

use lib 't/lib';
use Helper;

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'extract operationIds and identify duplicates' => sub {
  my $yaml = OPENAPI_PREAMBLE.<<'YAML';
components:
  callbacks:
    callback_a:
      $url_a:
        patch:
          operationId: operation_id_a
          callbacks:
            callback_z:
              $url_z:
                delete:
                  operationId: operation_id_z
  pathItems:
    path_item_c:
      get:
        operationId: operation_id_c
        callbacks:
          callback_d:
            $url_d:
              patch:
                operationId: operation_id_d
paths:
  /foo/{foo_id}:
    post:
      operationId: operation_id_e
      callbacks:
        callback_f:
          $url_f:
            patch:
              operationId: operation_id_f
webhooks:
  webhook_b:
    put:
      operationId: operation_id_b
YAML

  my $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => my $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string($yaml),
  );

  ok(!$doc->errors, 'no errors when parsing this document');
  cmp_deeply(
    $doc->_operationIds,
    {
      operation_id_a => '/components/callbacks/callback_a/$url_a/patch',
      operation_id_b => '/webhooks/webhook_b/put',
      operation_id_c => '/components/pathItems/path_item_c/get',
      operation_id_d => '/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch',
      operation_id_e => '/paths/~1foo~1{foo_id}/post',
      operation_id_f => '/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch',
      operation_id_z => '/components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
    },
    'extracted the correct location of all operationIds',
  );


  $doc = JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'http://localhost:1234/api',
    evaluator => $js = JSON::Schema::Modern->new,
    schema => $yamlpp->load_string($yaml =~ s/operation_id_[a-z]/operation_id_dupe/gr),
  );

  cmp_result(
    [ map $_->TO_JSON, $doc->errors ],
    [ map +{
        instanceLocation => '',
        keywordLocation => $_.'/operationId',
        absoluteKeywordLocation => str(Mojo::URL->new('http://localhost:1234/api#'.$_.'/operationId')),
        error => 'duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
      },
      (
        # sorted alphabetically, longer paths before shorter ones
        #'/components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete',
        '/components/callbacks/callback_a/$url_a/patch',
        '/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch',
        '/components/pathItems/path_item_c/get',
        '/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch',
        '/paths/~1foo~1{foo_id}/post',
        '/webhooks/webhook_b/put',
      )
    ],
    'duplicate operationIds all identified',
  );

  is(document_result($doc), substr(<<'ERRORS', 0, -1), 'stringified errors');
'/components/callbacks/callback_a/$url_a/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/components/pathItems/path_item_c/get/callbacks/callback_d/$url_d/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/components/pathItems/path_item_c/get/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/paths/~1foo~1{foo_id}/post/callbacks/callback_f/$url_f/patch/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/paths/~1foo~1{foo_id}/post/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
'/webhooks/webhook_b/put/operationId': duplicate of operationId at /components/callbacks/callback_a/$url_a/patch/callbacks/callback_z/$url_z/delete
ERRORS
};

done_testing;
