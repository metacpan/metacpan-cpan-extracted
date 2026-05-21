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
use utf8;

use lib 't/lib';
use Helper;
use JSON::Schema::Modern::Utilities qw(is_bool get_type is_type jsonp_set);
use OpenAPI::Modern::Utilities qw(coerce_primitive uri_encode);

my $openapi = OpenAPI::Modern->new(
  openapi_uri => 'http://localhost:1234/api',
  openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components: {}
YAML

no warnings 'redefine';
*OpenAPI::Modern::_evaluate_subschema = sub {1};

my $keyword_path = '/paths/~1foo/get/parameters/0';

sub _init_test ($data_path, $param_obj_data) {
  my $state = {
    initial_schema_uri => $openapi->openapi_uri,
    traversed_keyword_path => '',
    keyword_path => $keyword_path,
    data_path => $data_path,
    specification_version => 'draft2020-12',
    vocabularies => OAS_VOCABULARIES,
    errors => [],
    depth => 0,
    data => {},
  };

  # hack, to allow _fetch_from_uri and cache to work: patch schema, content
  jsonp_set($openapi->openapi_document->schema, $state->{keyword_path}.'/'.$_, $param_obj_data->{$_})
    foreach keys %$param_obj_data;

  $openapi->openapi_document->{_type_in_schema} //= {};
  my $path = $state->{keyword_path};
  my $len = length $path;
  delete $openapi->openapi_document->{_type_in_schema}{$_}
    foreach grep substr($_, 0, $len) eq $path, keys $openapi->openapi_document->{_type_in_schema}->%*;

  return $state;
}

subtest 'path parameters' => sub {
  my @tests = (
    # name (test name)
    # param_obj (from OAD)
    # input (value of path_captures, as provided by find_path_item, or undef if missing)
    # content => expected data that was parsed from serialized string; omit when nothing is to be found
    # errors => compared to what is collected from $state, defaults to []
    # todo
    {
      name => 'missing parameter (always required)',
      param_obj => { name => 'missing' },
      input => undef,
      errors => [
        {
          instanceLocation => '/request/uri/path',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing path parameter: missing',
        },
      ],
    },
    # encoded with media-type
    {
      name => 'missing',
      param_obj => { name => 'missing_json_content', content => { 'application/json' => {} } },
      input => undef,
      errors => [
        {
          instanceLocation => '/request/uri/path',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing path parameter: missing_json_content',
        },
      ],
    },
    {
      name => 'non-ascii characters in path captures must be percent-encoded',
      param_obj => { name => 'color', content => { 'application/json' => {} } },
      input => 'cølör',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'non-ascii character detected in parameter value: not deserializable',
        },
      ],
    },
    {
      name => 'numeric string',
      param_obj => { name => 'json_content', content => { 'application/json' => {} } },
      input => '3',
      content => 3, # numeric, not string!
    },

    # style=simple

    [
      [ qw(style content input) ],
      [ 'simple', undef, '' ],        # not reversible
      [ 'simple', 0, '0' ],
      [ 'simple', 1, '1' ],
      [ 'simple', false, '' ],        # not reversible
      [ 'simple', false, '0' ],
      [ 'simple', true, '1' ],
      [ 'simple', false, 'false' ],   # not reversible
      [ 'simple', true, 'true' ],     # not reversible
      [ 'simple', 0, '0' ],
      [ 'simple', 1, '1' ],
      [ 'simple', 3, '3' ],
      [ 'simple', -42, '-42' ],
      [ 'simple', '', '' ],
      [ 'simple', 'red', 'red' ],
      [ 'simple', 'red,green', 'red%2Cgreen' ],
      [ 'simple', 'red+green', 'red+green' ],
      [ 'simple', 'red+green', 'red%2Bgreen' ],
      # ? and # must be escaped as they signal the end of the path section of the URI
      [ 'simple', 'red?green', 'red%3Fgreen' ],
      [ 'simple', 'red#green', 'red%23green' ],
      [ 'simple', 'red?green&blue', 'red%3Fgreen&blue' ],
      [ 'simple', 'red?green&blue', 'red%3Fgreen%26blue' ],
      [ 'simple', 'red?green&blue#black', 'red%3Fgreen&blue%23black' ],
      [ 'simple', 'red%green', 'red%25green' ],
      [ 'simple', " i have spaces  \t ", " i have spaces  \t " ],
      [ 'simple', ' red,  green ', ' red,  green ' ],
      [ 'simple', 'red﹠green', 'red%EF%B9%A0green' ],
    ],
    [
      [ qw(style explode content input) ],
      [ 'simple', false, [], '' ],
      [ 'simple', true,  [], '' ],
      [ 'simple', false, {}, '' ],
      [ 'simple', true,  {}, '' ],
      [ 'simple', false, [ '', '', '' ], ',,' ],
      [ 'simple', true,  [ '', '', '' ], ',,' ],
      [ 'simple', false, [ 'red' ], 'red' ],
      [ 'simple', true,  [ 'red' ], 'red' ],
      # , must be escaped to not be treated as a delimiter
      [ 'simple', false, [ 'red,green', 'blue' ], 'red%2Cgreen,blue' ],
      [ 'simple', true,  [ 'red,green', 'blue' ], 'red%2Cgreen,blue' ],
      [ 'simple', false, [ qw(blue black brown) ], 'blue,black,brown' ],
      [ 'simple', true,  [ qw(blue black brown) ], 'blue,black,brown' ],
      [ 'simple', false, { R => '', G => '', B => '' }, 'R,,G,,B,' ],
      [ 'simple', true,  { R => '', G => '', B => '' }, 'R,G,B' ],

      [ 'simple', false, { foo => 'bar', baz => '' }, 'foo,bar,baz,' ],
      [ 'simple', true,  { foo => 'bar', baz => '' }, 'foo=bar,baz' ],
      [ 'simple', false, { 'foo=bar' => 'baz', bloop => '' },                'foo=bar,baz,bloop,' ],
      [ 'simple', true,  { foo => 'bar', baz => '', bloop => '', '' => '' }, 'foo=bar,baz,bloop,' ],
      [ 'simple', false, { foo => 'bar=baz', bloop => '' },                  'foo,bar=baz,bloop,' ],
      [ 'simple', true,  { foo => '', bar => 'baz', bloop => '', '' => '' }, 'foo,bar=baz,bloop,' ],
      [ 'simple', false, { 'foo=bar=baz' => 'bloop' },                       'foo=bar=baz,bloop' ],
      [ 'simple', true,  { foo => 'bar=baz' => bloop => '' },                'foo=bar=baz,bloop' ],

      [ 'simple', false, { R => '100', G => '200', B => '' }, 'R,100,G,200,B,' ],
      [ 'simple', true,  { R => '100', G => '200', B => '' }, 'R=100,G=200,B' ],
      [ 'simple', false, { qw(R 100 G 200 B 150) }, 'R,100,G,200,B,150' ],
      [ 'simple', true,  { qw(R 100 G 200 B 150) }, 'R=100,G=200,B=150' ],
      [ 'simple', false, { 'R,X' => '100', G => '200', 'B,Y' => '150' }, 'R%2CX,100,G,200,B%2CY,150' ],
      [ 'simple', true,  { 'R,X' => '100', G => '200', 'B=Y' => '150' }, 'R%2CX=100,G=200,B%3DY=150' ],
    ],
    [
      [ qw(style name explode content input) ],
      [ 'simple', 'cølör', false, [ 'blue−black', 'blackish,green', '100𝑥brown=fl¡p' ],
        'blue%E2%88%92black,blackish%2Cgreen,100%F0%9D%91%A5brown=fl%C2%A1p' ],
      [ 'simple', 'cølör', true, [ 'blue−black', 'blackish,green', '100𝑥brown=fl¡p' ],
        'blue%E2%88%92black,blackish%2Cgreen,100%F0%9D%91%A5brown=fl%C2%A1p' ],
      [ 'simple', 'cølör', false, { 'blue−black' => 'yes!', 'blackish,green' => '¿no?', '100𝑥brown' => 'fl¡p' },
        'blue%E2%88%92black,yes!,blackish%2Cgreen,%C2%BFno%3f,100%F0%9D%91%A5brown,fl%C2%A1p' ],
      [ 'simple', 'cølör', true, { 'blue−black' => 'yes!', 'blackish,green' => '¿no?', '100𝑥brown' => 'fl¡p' },
        'blue%E2%88%92black=yes!,blackish%2Cgreen=%C2%BFno%3f,100%F0%9D%91%A5brown=fl%C2%A1p' ],
    ],

    {
      name => 'with boolean schema, return empty string as string',
      param_obj => { name => 'color', schema => true },
      input => '',
      content => '',
    },
    {
      name => 'with boolean schema, return encoded data as decoded string',
      param_obj => { name => 'color', schema => true },
      input => 'red%EF%B9%A0green',
      content => 'red﹠green',
    },
    {
      name => 'with boolean schema, return numeric data as string',
      param_obj => { name => 'color', schema => true },
      input => 20,
      content => '20',
    },
    {
      name => 'non-ascii characters in path captures must be percent-encoded',
      param_obj => { name => 'color' },
      input => 'cølör',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'non-ascii character detected in parameter value: not deserializable',
        },
      ],
    },
    {
      name => 'any type is permitted, default to string',
      param_obj => { name => 'color', schema => {} },
      input => 'red',
      content => 'red',
    },
    {
      name => 'no type is permitted',
      param_obj => { name => 'color', schema => { allOf => [ { type => 'string' }, { type => 'null' } ] } },
      input => 'red',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to any type',
        },
      ],
    },
    {
      name => 'empty string but not deserializable',
      param_obj => { name => 'color', schema => { type => 'number' } },
      input => '',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (number)',
        },
      ],
    },
    {
      name => 'number or string prefers number',
      param_obj => { name => 'color', schema => { type => [ qw(string number) ] } },
      input => '3',
      content => 3,
    },
    {
      name => 'explode=false, array with non-string items',
      param_obj => { name => 'color', schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => ',0,42,100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=true, array with non-string items',
      param_obj => { name => 'color', explode => true, schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => ',0,42,100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'string or object prefers object',
      param_obj => { name => 'color', schema => { type => [ qw(string object) ] } },
      input => 'R,100,G,200,B,',
      content => { R => '100', G => '200', B => '' },
    },
    {
      name => 'explode=false, bad object',
      param_obj => { name => 'color', schema => { type => 'object' } },
      input => 'R,100,G,200,B',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'explode=false, bad object, fall through to string',
      param_obj => { name => 'color', schema => { type => [ qw(object string) ] } },
      input => 'R,100,G,200,B',
      content => 'R,100,G,200,B',
    },
    {
      name => 'explode=false, bad object, fall through to array',
      param_obj => { name => 'color', schema => { type => [ qw(array object string) ] } },
      input => 'R,100,G,200,B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'explode=false, prefer object over array or string',
      param_obj => { name => 'color', schema => { type => [ qw(array string object) ] } },
      input => 'R,100,G,200,B,150',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=false, object with non-string properties',
      param_obj => { name => 'color', schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => 'a,,b,0,c,42,d,100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'explode=true, bad object',
      param_obj => { name => 'color', explode => true, schema => { type => 'object' } },
      input => 'R=100,G=200,B=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "simple" for object (invalid separator at key "B")',
        },
      ],
    },
    {
      name => 'explode=true, bad object, fall through to string',
      param_obj => { name => 'color', explode => true, schema => { type => [ qw(object string) ] } },
      input => 'R=100,G=200,B=',
      content => 'R=100,G=200,B=',
    },
    {
      name => 'explode=true, bad object, fall through to array',
      param_obj => { name => 'color', explode => true, schema => { type => [ qw(array object) ] } },
      input => 'R=100,G=200,B=',
      content => [ qw(R=100 G=200 B=) ],
    },
    {
      name => 'explode=true, object with empty value, prefer object',
      param_obj => { name => 'color', explode => true, schema => { type => [ qw(array object) ] } },
      input => 'R=100,G=200,B',
      content => { R => '100', G => '200', B => '' },
    },
    {
      name => 'explode=true, object with non-string properties',
      param_obj => { name => 'color', explode => true, schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => 'a,b=0,c=42,d=100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },

    # style=matrix

    [
      [ qw(style content input) ],
      [ 'matrix', undef, '' ],
      [ 'matrix', 0, ';color=0' ],
      [ 'matrix', 1, ';color=1' ],
      [ 'matrix', false, ';color' ],         # not reversible
      [ 'matrix', false, ';color=0' ],
      [ 'matrix', true, ';color=1' ],
      [ 'matrix', false, ';color=false' ],   # not reversible
      [ 'matrix', true, ';color=true' ],     # not reversible
      [ 'matrix', 3, ';color=3' ],
      [ 'matrix', '', ';color' ],
      [ 'matrix', 'red', ';color=red' ],
      [ 'matrix', 'red;green=blue', ';color=red%3Bgreen%3Dblue' ],
    ],
    [
      [ qw(style name content input) ],
        # ; and = are in the reserved set and not encoded
      [ 'matrix', 'cølör', 'red﹠green', ';c%C3%B8l%C3%B6r=red%EF%B9%A0green' ],
    ],
    [
      [ qw(style explode content input) ],
      [ 'matrix', false, [], '' ],
      [ 'matrix', true,  [], '' ],
      [ 'matrix', false, {}, '' ],
      [ 'matrix', true,  {}, '' ],
      [ 'matrix', false, [], ';color' ],    # not reversible
      [ 'matrix', true,  [''], ';color' ],
      [ 'matrix', false, {}, ';color' ],    # not reversible
      [ 'matrix', true,  {}, ';' ],         # not reversible
      [ 'matrix', false, [ '', '', '' ], ';color=,,' ],
      [ 'matrix', true,  [ '', '', '' ], ';color;color;color' ],
      [ 'matrix', false, [ qw(blue black brown) ], ';color=blue,black,brown' ],
      [ 'matrix', true,  [ qw(blue black brown) ], ';color=blue;color=black;color=brown' ],
      [ 'matrix', false, [ 'red,green;black', 'blue' ], ';color=red%2Cgreen%3Bblack,blue' ],
      [ 'matrix', true,  [ 'red,green;black', 'blue' ], ';color=red%2Cgreen%3Bblack;color=blue' ],
      [ 'matrix', false, { R => '', G => '', B => '' }, ';color=R,,G,,B,' ],
      [ 'matrix', true,  { R => '', G => '', B => '' }, ';R;G;B' ],
      [ 'matrix', false, { R => '100', G => '200', B => '' }, ';color=R,100,G,200,B,' ],
      [ 'matrix', true,  { R => '100', G => '200', B => '' }, ';R=100;G=200;B' ],
      [ 'matrix', false, { qw(R 100 G 200 B 150) }, ';color=R,100,G,200,B,150' ],
      [ 'matrix', true,  { qw(R 100 G 200 B 150) }, ';R=100;G=200;B=150' ],
      [ 'matrix', false, { 'R,X' => '100', G => '200', 'B,Y' => '150' }, ';color=R%2CX,100,G,200,B%2CY,150' ],
      [ 'matrix', true,  { 'R,X' => '100', G => '200', 'B=Y' => '150' }, ';R%2CX=100;G=200;B%3DY=150' ],
      [ 'matrix', true,  { color => 'brown' }, ';color=blue;color=black;color=brown' ],
    ],
    [
      [ qw(style name explode content input) ],
      [ 'matrix', 'cølör', false, [ 'blue−black', 'blackish,green', '100𝑥brown' ],
        ';c%C3%B8l%C3%B6r=blue%E2%88%92black,blackish%2Cgreen,100%F0%9D%91%A5brown' ],
      [ 'matrix', 'cølör', true,  [ 'blue−black', 'blackish,green', '100𝑥brown' ],
        ';c%C3%B8l%C3%B6r=blue%E2%88%92black;c%C3%B8l%C3%B6r=blackish%2Cgreen;c%C3%B8l%C3%B6r=100%F0%9D%91%A5brown' ],
      [ 'matrix', 'cølör', false, { 'blue−black' => 'yes!', 'blackish,green' => '¿no?', '100𝑥brown' => 'fl¡p' },
        ';c%C3%B8l%C3%B6r=blue%E2%88%92black,yes!,blackish%2Cgreen,%C2%BFno%3f,100%F0%9D%91%A5brown,fl%C2%A1p' ],
      [ 'matrix', 'cølör', true,  { 'blue−black' => 'yes!', 'blackish,green' => '¿no?', '100𝑥brown' => 'fl¡p' },
        ';blue%E2%88%92black=yes!;blackish%2Cgreen=%C2%BFno%3f;100%F0%9D%91%A5brown=fl%C2%A1p' ],
    ],

    {
      name => 'with boolean schema, empty string is null',
      param_obj => { style => 'matrix', name => 'color', schema => true },
      input => '',
      content => undef,
    },
    {
      name => 'any type is permitted, default to string',
      param_obj => { name => 'color', style => 'matrix', schema => {} },
      input => ';color=red,green,blue',
      content => 'red,green,blue',
    },
    {
      name => 'no type is permitted',
      param_obj => { name => 'color', style => 'matrix', schema => { allOf => [ { type => 'string' }, { type => 'null' } ] } },
      input => ';color=red,green,blue',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to any type',
        },
      ],
    },
    {
      name => 'empty string without prefix',
      param_obj => { name => 'color', style => 'matrix' },
      input => '',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" (invalid prefix)',
        },
      ],
    },
    {
      name => 'empty string with bad prefix',
      param_obj => { name => 'color', style => 'matrix' },
      input => ';color=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" (invalid prefix)',
        },
      ],
    },
    {
      name => 'explode=false, array with non-string items',
      param_obj => { name => 'color', style => 'matrix', schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => ';color=,0,42,100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=true, array of empty values with error',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => { type => 'array' } },
      input => ';color=;color=;color=',
      errors => [
        (map +{
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" for array (invalid separator at index '.$_.')',
        }, 0..2),
      ],
    },
    {
      name => 'explode=true, empty array, with bad key name',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => { type => 'array' } },
      input => ';color=red;color1=green;color=blue',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" for array (invalid element name at "color1")',
        },
      ],
    },
    {
      name => 'explode=true, bad array, fall through to object',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => { type => [ qw(array object) ] } },
      input => ';R=100;G=200;B=150',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=true, array with non-string items',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => ';color;color=0;color=42;color=100',
      content => [ undef, false, 42, '100' ],
    },
    {
      # '=' is only appended when the serialized value is not empty
      name => 'explode=false, empty object with error',
      param_obj => { name => 'color', style => 'matrix', schema => { type => 'object' } },
      input => ';color=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" (invalid prefix)',
        },
      ],
    },
    {
      name => 'explode=false, bad object',
      param_obj => { name => 'color', style => 'matrix', schema => { type => 'object' } },
      input => ';color=R,100,G,200,B',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'explode=false, bad object, fall through to string',
      param_obj => { name => 'color', style => 'matrix', schema => { type => [ qw(object string) ] } },
      input => ';color=R,100,G,200,B',
      content => 'R,100,G,200,B',
    },
    {
      name => 'explode=false, bad object, fall through to array',
      param_obj => { name => 'color', style => 'matrix', schema => { type => [ qw(array object) ] } },
      input => ';color=R,100,G,200,B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'explode=false, prefer object over array or string',
      param_obj => { name => 'color', style => 'matrix', schema => { type => [qw(array string object)] } },
      input => ';color=R,100,G,200,B,150',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=false, object with non-string properties',
      param_obj => { name => 'color', style => 'matrix', schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => ';color=a,,b,0,c,42,d,100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'explode=true, object of empty values with bad =',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => { type => [qw(array object)] } },
      input => ';R=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" for object (invalid separator at key "R")',
        },
      ],
    },
    {
      name => 'explode=true, bad object',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => { type => 'object' } },
      input => ';R=100;G=200;B=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "matrix" for object (invalid separator at key "B")',
        },
      ],
    },
    {
      name => 'explode=true, object with non-string properties',
      param_obj => { name => 'color', style => 'matrix', explode => true, schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => ';a;b=0;c=42;d=100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },

    # style=label

    # style, explode, deserialized data, serialized string
    [
      [ qw(style content input) ],
      [ 'label',  undef, '' ],
      [ 'label',  0, '.0' ],
      [ 'label',  1, '.1' ],
      [ 'label',  false, '.' ],
      [ 'label',  false, '.0' ],
      [ 'label',  true, '.1' ],
      [ 'label',  false, '.false' ],
      [ 'label',  true, '.true' ],
      [ 'label',  3, '.3' ],
      [ 'label',  '', '.' ],
      [ 'label',  'red', '.red' ],
      [ 'label',  'red﹠gr.e.en', '.red%EF%B9%A0gr%2Ee%2Een' ], # . is in "unreserved" - must be manually encoded
    ],
    [
      [ qw(style explode content input) ],
      [ 'label', false, [], '' ],
      [ 'label', true,  [], '' ],
      [ 'label', false, {}, '' ],
      [ 'label', true,  {}, '' ],
      [ 'label', false, [], '.' ],    # not reversible
      [ 'label', true,  [], '.' ],    # not reversible
      [ 'label', false, {}, '.' ],    # not reversible
      [ 'label', true,  {}, '.' ],    # not reversible
      [ 'label', false, [ '', '', '' ], '.,,' ],
      [ 'label', true,  [ '', '', '' ], '...' ],
      [ 'label', false, { R => '', G => '', B => '' }, '.R,,G,,B,' ],
      [ 'label', true,  { R => '', G => '', B => '' }, '.R.G.B' ],
      [ 'label', false, { R => '100', G => '200', B => '' }, '.R,100,G,200,B,' ],
      [ 'label', true,  { R => '100', G => '200', B => '' }, '.R=100.G=200.B' ],
      [ 'label', false, [ qw(blue black brown) ], '.blue,black,brown' ],
      [ 'label', true,  [ qw(blue black brown) ], '.blue.black.brown' ],
      [ 'label', false, [ 'red.green', 'blue' ], '.red%2Egreen,blue' ],
      [ 'label', true,  [ 'red.green', 'blue' ], '.red%2Egreen.blue' ],
      [ 'label', false, [ 'blue−black', 'blackish,gr.e.en', '100𝑥brown' ],
        '.blue%E2%88%92black,blackish%2Cgr%2Ee%2Een,100%F0%9D%91%A5brown' ],
      [ 'label', true,  [ 'blue−black', 'blackish,gr.e.en', '100𝑥brown' ],
        '.blue%E2%88%92black.blackish%2Cgr%2Ee%2Een.100%F0%9D%91%A5brown' ],
      [ 'label', false, { qw(R 100 G 200 B 150) }, '.R,100,G,200,B,150' ],
      [ 'label', true,  { qw(R 100 G 200 B 150) }, '.R=100.G=200.B=150' ],
      [ 'label', false, { 'R.X' => '100', G => '200', 'B,Y' => '150' }, '.R%2EX,100,G,200,B%2CY,150' ],
      [ 'label', true,  { 'R.X' => '100', G => '200', 'B=Y' => '150' }, '.R%2EX=100.G=200.B%3DY=150' ],
      [ 'label', false, { 'blue−black' => 'yes!', 'blackish,gr.e.en' => '¿no?', '100𝑥brown' => 'fl¡p' },
        '.blue%E2%88%92black,yes!,blackish%2Cgr%2Ee%2Een,%C2%BFno%3f,100%F0%9D%91%A5brown,fl%C2%A1p' ],
      [ 'label', true,  { 'blue−black' => 'yes!', 'blackish,gr.e.en' => '¿no?', '100𝑥brown' => 'fl¡p' },
        '.blue%E2%88%92black=yes!.blackish%2Cgr%2Ee%2Een=%C2%BFno%3f.100%F0%9D%91%A5brown=fl%C2%A1p' ],
    ],

    {
      name => 'with boolean schema, empty string is null',
      param_obj => { style => 'label', name => 'color', schema => true },
      input => '',
      content => undef,
    },
    {
      name => 'any type is permitted, default to string',
      param_obj => { name => 'color', style => 'label', schema => {} },
      input => '.red,green,blue',
      content => 'red,green,blue',
    },
    {
      name => 'no type is permitted',
      param_obj => { name => 'color', style => 'label', schema => { allOf => [ { type => 'string' }, { type => 'null' } ] } },
      input => '.red,green,blue',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to any type',
        },
      ],
    },
    {
      name => 'explode=false, array with non-string items',
      param_obj => { name => 'color', style => 'label', schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => '.,0,42,100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=true, array with non-string items',
      param_obj => { name => 'color', style => 'label', explode => true, schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      input => '..0.42.100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=false, bad object',
      param_obj => { name => 'color', style => 'label', schema => { type => 'object' } },
      input => '.R,100,G,200,B',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'explode=false, bad object, fall through to string',
      param_obj => { name => 'color', style => 'label', schema => { type => [ qw(object string) ] } },
      input => '.R,100,G,200,B',
      content => 'R,100,G,200,B',
    },
    {
      name => 'explode=false, bad object, fall through to array',
      param_obj => { name => 'color', style => 'label', schema => { type => [ qw(array object) ] } },
      input => '.R,100,G,200,B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'explode=false, prefer object',
      param_obj => { name => 'color', style => 'label', schema => { type => [qw(array object)] } },
      input => '.R,100,G,200,B,150',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=false, object with non-string properties',
      param_obj => { name => 'color', style => 'label', schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => '.a,,b,0,c,42,d,100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'explode=true, object with bad =',
      param_obj => { name => 'color', style => 'label', explode => true, schema => { type => 'object' } },
      input => '.R=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "label" for object (invalid separator at key "R")',
        },
      ],
    },
    {
      name => 'explode=true, bad object',
      param_obj => { name => 'color', style => 'label', explode => true, schema => { type => 'object' } },
      input => '.R=100.G=200.B=',
      errors => [
        {
          instanceLocation => '/request/uri/path/color',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "label" for object (invalid separator at key "B")',
        },
      ],
    },
    {
      name => 'explode=true, bad object, fall through to array',
      param_obj => { name => 'color', style => 'label', explode => true, schema => { type => [ qw(array object) ] } },
      input => '.R=100.G=200.B=',
      content => [ qw(R=100 G=200 B=) ],
    },
    {
      name => 'explode=true, bad object, fall through to string',
      param_obj => { name => 'color', style => 'label', explode => true, schema => { type => [ qw(string object) ] } },
      input => '.R=100.G=200.B=',
      content => 'R=100.G=200.B=',
    },
    {
      name => 'explode=true, prefer object',
      param_obj => { name => 'color', style => 'label', explode => true, schema => { type => [qw(array object)] } },
      input => '.R=100.G=200.B=150',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=true, object with non-string properties',
      param_obj => { name => 'color', style => 'label', explode => true, schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      input => '.a.b=0.c=42.d=100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
  );

  @tests = map +(
    ref eq 'ARRAY'
      ? map +{
          name => defined $_->{explode} ? 'explode='.($_->{explode}?'true':'false') : '',
          param_obj => {
            name => $_->{name}//'color',
            style => $_->{style},
            defined $_->{explode} ? $_->%{explode} : (),
            schema => { type => get_type($_->{content}) },
          },
          $_->%{qw(input content)},
        }, arrays_to_hashes($_)->@*
      : $_
  ), @tests;

  foreach my $test (@tests) {
    die 'missing test param "param_obj"' if not exists $test->{param_obj};
    die 'missing test param "input"' if not exists $test->{input};

    subtest 'path '
        .($test->{param_obj}{content} ? 'encoded with media-type' : 'style='.($test->{param_obj}{style}//'simple'))
        .(length $test->{name} ? ', '.$test->{name} : '').': '
        .(defined $test->{input} ? '"'.$test->{input}.'"' : '<missing>')
        .' -> '.$::dumper->encode($test->{content}) => sub {

      my $param_obj = +{
        # default to type=string in the absence of an override
        exists $test->{param_obj}{content} ? () : (schema => { type => 'string' }),
        $test->{param_obj}->%*,
        in => 'path',
        required => true,
      };

      my $result = $openapi->evaluator->evaluate(
        $param_obj,
        OpenAPI::Modern::Utilities::DEFAULT_METASCHEMA()->{'3.2'}.'#/$defs/parameter',
      );
      fail('parameter object is valid'), note($result), return if not $result->valid;

      my $state = _init_test('/request/uri/path', +{ $param_obj->%{qw(schema content)} });

      my $valid = $openapi->_validate_parameter($state, $param_obj,
        path_captures => { defined $test->{input} ? ($param_obj->{name} => $test->{input}) : () });
      die 'validity inconsistent with error count; got valid=', 0+!!$valid, ', errors are: ',
        $::encoder->encode($state->{errors}) if $valid xor !$state->{errors}->@*;

      my $todo;
      $todo = todo $test->{todo} if $test->{todo};

      is_equal(
        [ map $_->TO_JSON, $state->{errors}->@* ],
        $test->{errors}//[],
        ($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred',
      );

      if (not exists $test->{content}) {
        ok(!keys $state->{data}->%*, 'no content was extracted')
          or note("extracted content:\n", $::encoder->encode($state->{data}));
      }
      else {
        ok(exists $state->{data}{request}{uri}{path}{$param_obj->{name}}, 'content was extracted');
        is_equal(
          $state->{data}{request}{uri}{path}{$param_obj->{name}},
          $test->{content},
          defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted',
        );
      }
    };
  }
};

my @query_tests;

subtest 'query parameters' => sub {
  my @tests = (
    # name (test name)
    # param_obj (from OAD)
    # queries => raw query string, without leading '?'
    # content => expected data that was parsed from serialized string; omit when nothing is to be found
    # errors => compared to what is collected from $state, defaults to []
    # todo
    {
      name => 'missing but not required',
      param_obj => { name => 'q', content => { 'application/json' => { schema => { type => 'object' } } } },
      queries => 'foo=1&bar=2',
    },
    {
      name => 'missing, required',
      param_obj => { name => 'q', required => true, content => { 'text/plain' => {} } },
      queries => 'foo=1&bar=2',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty string, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, content => { 'text/plain' => {} } },
      queries => 'foo=1&q=&bar=2',
      # content not extracted, but also no errors
    },
    {
      name => 'empty string, allowEmptyValue=true, required',
      param_obj => { name => 'q', allowEmptyValue => true, required => true, content => { 'text/plain' => {} } },
      queries => 'foo=1&q=&bar=2',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      param_obj => { name => 'foo', content => { 'application/json' => {} } },
      queries => 'foo=1&bar=2',
      content => 1, # number, not string!
    },
    {
      param_obj => { name => 'foo', content => { 'application/json' => {} } },
      queries => 'foo=%7B%22a%22:1,%22b%22:2%7D',
      content => { a => 1, b => 2 },
    },

    # style=form

    [
      [ qw(style content queries skip_cookie) ],
      [ 'form', undef, 'q', 1 ],               # not reversible
      [ 'form', undef, 'q=' ],                 # not reversible
      [ 'form', 0, 'q=0' ],
      [ 'form', 1, 'q=1' ],
      [ 'form', false, 'q', 1 ],               # not reversible
      [ 'form', false, 'q=' ],                 # not reversible
      [ 'form', false, 'q=0' ],
      [ 'form', true, 'q=1' ],
      [ 'form', false, 'q=false' ],            # not reversible
      [ 'form', true, 'q=true' ],              # not reversible
      [ 'form', 0, 'q=0' ],
      [ 'form', 1, 'q=1' ],
      [ 'form', -42, 'q=-42' ],
      [ 'form', '', 'q', 1 ],                  # not reversible
      [ 'form', '', 'q=' ],
      [ 'form', 'red', 'q=red' ],
      [ 'form', '3', 'q=3' ],
      [ 'form', '3', 'q=1&q=2&q=3&a=1&b=2' ],  # not reversible
      [ 'form', 'a+b', 'q=a%2Bb' ],
      [ 'form', 'a&b', 'q=a%26b' ],
      [ 'form', 'a#b', 'q=a%23b' ],
      [ 'form', 'a?b', 'q=a%3Fb' ],
      [ 'form', '100%', 'q=100%25' ],
      [ 'form', '100%25', 'q=100%2525' ],
      [ 'form', 'x=y', 'q=x%3Dy' ],
    ],
    [
      [ qw(style name content queries) ],
      [ 'form', 'cølör', 'blue/blåck', 'c%C3%B8l%C3%B6r=blue%2Fbl%C3%A5ck&a=b&c=d' ],
      [ 'form', 'cølör', 'blue/blåck', 'c%C3%B8l%C3%B6r=blue%2Fbl%C3%A5ck' ],
    ],
    [
      [ qw(style explode content queries skip_cookie) ],
      [ 'form', false, [], 'q' ],                     # not reversible
      [ 'form', false, [], 'q=' ],
      [ 'form', true,  [''], 'q', 1 ],                # not reversible
      [ 'form', true,  [''], 'q=' ],
      [ 'form', false, [ '', '', '' ], 'q=,,' ],
      [ 'form', true,  [ '', '', '' ], 'q=&q=&q=' ],
      [ 'form', false, [ 'red' ], 'q=red' ],
      [ 'form', false, [ '0', '1', '2' ], 'q=0,1,2' ],
      [ 'form', false, [ '0', '0', '0' ], 'q=0,0,0' ],
      [ 'form', false, [ qw(blue black brown) ], 'q=blue,black,brown' ],
      [ 'form', true,  [ qw(blue black brown) ], 'q=blue&q=black&q=brown' ],

      [ 'form', false, {}, 'q' ],                     # not reversible
      [ 'form', false, {}, 'q=' ],
      [ 'form', true,  { q => '' }, 'q', 1 ],         # not reversible
      [ 'form', true,  { q => '' }, 'q=' ],
      [ 'form', true,  { x => '' }, 'x', 1 ],         # not reversible
      [ 'form', true,  { x => '' }, 'x=' ],
      [ 'form', false, { R => '', G => '', B => '' }, 'q=R,,G,,B,' ],
      [ 'form', true,  { R => '', G => '', B => '' }, 'R=&G&=&B=' ],
      [ 'form', false, { R => '100', G => '200', B => '' }, 'q=R,100,G,200,B,' ],
      [ 'form', true,  { R => '100', G => '200', B => '' }, 'R=100&G=200&B=' ],
      [ 'form', false, { qw(R 100 G 200 B 150) }, 'q=R,100,G,200,B,150' ],
      [ 'form', true,  { qw(R 100 G 200 B 150) }, 'R=100&G=200&B=150' ],
      [ 'form', false, { 'blue−black', 'yes!', 'blackish﹠green', '¿no?', '100𝑥brown', 'fl¡p' },
        'q=blue%E2%88%92black,yes!,blackish%EF%B9%A0green,%C2%BFno?,100%F0%9D%91%A5brown,fl%C2%A1p' ],
      [ 'form', true,  { 'blue−black', 'yes!', 'blackish﹠green', '¿no?', '100𝑥brown', 'fl¡p' },
        'blue%E2%88%92black=yes!&blackish%EF%B9%A0green=%C2%Bfno?&100%f0%9D%91%A5brown=fl%C2%A1p' ],
    ],
    [
      [ qw(style explode name content queries) ],
      [ 'form', false, 'cølör', [ 'blue−black', 'black/ish&green', '100𝑥brown' ],
        'c%C3%B8l%C3%B6r=blue%E2%88%92black,black%2Fish%26green,100%F0%9D%91%A5brown' ],
      [ 'form', true,  'cølör', [ 'blue−black', 'black/ish&gr,e,en', '100𝑥brown' ],
        'c%C3%B8l%C3%B6r=blue%E2%88%92black&c%C3%B8l%C3%B6r=black%2Fish%26gr%2Ce%2Cen&c%C3%B8l%C3%B6r=100%F0%9D%91%A5brown' ],
      [ 'form', false, 'cølör', { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
        'c%C3%B8l%C3%B6r=r%C3%A9d,100%F0%9D%91%A5,gr%C9%98%C9%87n,%C2%A1ja,bl%C3%B8%C3%B6,%C2%BFne%C3%AEn&a=b&c=d' ],
      [ 'form', true,  'cølör', { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
        'r%C3%A9d=100%F0%9D%91%A5&gr%C9%98%C9%87n=%C2%A1ja&bl%C3%B8%C3%B6=%C2%BFne%C3%AEn' ],
    ],

    {
      name => 'missing',
      param_obj => { name => 'q' },
      queries => 'a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'missing, required',
      param_obj => { name => 'q', required => true },
      queries => 'a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty string, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'with boolean schema, return empty string as string',
      param_obj => { name => 'q', schema => false },
      queries => 'q=',
      content => '',
    },
    {
      name => 'with boolean schema, return encoded data as decoded string',
      param_obj => { name => 'color', schema => false },
      queries => 'color=red%EF%B9%A0green',
      content => 'red﹠green',
    },
    {
      name => 'explode=false, any type is permitted, default to string',
      param_obj => { name => 'color', explode => false, schema => {} },
      queries => 'color=red,green,blue',
      content => 'red,green,blue',
      skip_cookie => 1,
    },
    {
      name => 'explode=true, any type is permitted, default to string',
      param_obj => { name => 'color', schema => {} },
      queries => 'color=red,green,blue',
      content => 'red,green,blue',
      skip_cookie => 1,
    },
    {
      name => 'no type is permitted',
      param_obj => { name => 'color', schema => { allOf => [ { type => 'string' }, { type => 'null' } ] } },
      queries => 'color=red',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to any type',
        },
      ],
    },
    {
      name => 'empty string but not deserializable',
      param_obj => { name => 'q', schema => { type => 'number' } },
      queries => 'q=',
      errors => [
        {
          instanceLocation => '/request/uri/query/q',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (number)',
        },
      ],
    },
    {
      name => 'number preferred over string',
      param_obj => { name => 'color', schema => { type => [ qw(string number) ] } },
      queries => 'color=20',
      content => 20,
    },
    {
      name => 'explode=false, array, missing',
      param_obj => { name => 'q', explode => false, schema => { type => 'array' } },
      queries => 'a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=false, array, missing, required',
      param_obj => { name => 'q', explode => false, required => true, schema => { type => 'array' } },
      queries => 'a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, array, missing, allowEmptyValue=true',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=false, array, missing, allowEmptyValue=true, required',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, required => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, empty array, allowEmptyValue=true',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
    },
    {
      name => 'explode=false, empty array, allowEmptyValue=true, required',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, required => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, array, empty elements, allowEmptyValue=true',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=,,&a=b&c=d',
      content => [ '', '', '' ],
    },
    {
      name => 'explode=false, ask for array or object; object will fail',
      param_obj => { name => 'color', explode => false, schema => { type => [ qw(array object) ] } },
      queries => 'color=R,100,G,200,B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'explode=false, array with non-string items',
      param_obj => { name => 'color', explode => false, schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      queries => 'color=,0,42,100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=true, array, missing',
      param_obj => { name => 'q', schema => { type => 'array' } },
      queries => 'a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=true, array, missing, required',
      param_obj => { name => 'q', required => true, schema => { type => 'array' } },
      queries => 'a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=true, array, missing, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=true, array, missing, allowEmptyValue=true, required',
      param_obj => { name => 'q', allowEmptyValue => true, required => true, schema => { type => 'array' } },
      queries => 'q=&q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty array, explode=true, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
    },
    {
      name => 'empty array, explode=true, allowEmptyValue=true, required',
      param_obj => { name => 'q', allowEmptyValue => true, required => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=true, array, some empty elements, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=1&q=&q=&a=b&c=d',
      content => [ '1' ],
    },
    {
      name => 'explode=true, array, all empty elements, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&q=&q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=true, array with non-string items',
      param_obj => { name => 'color', schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      queries => 'color=&color=0&color=42&color=100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=false, object, missing',
      param_obj => { name => 'q', explode => false, schema => { type => 'object' } },
      queries => 'a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=false, object, missing, required',
      param_obj => { name => 'q', explode => false, required => true, schema => { type => 'object' } },
      queries => 'a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, object, missing, allowEmptyValue=true',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=false, object, missing, allowEmptyValue=true, required',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, empty object, allowEmptyValue=true',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
    },
    {
      name => 'explode=false, empty object, allowEmptyValue=true, required',
      param_obj => { name => 'q', explode => false, allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'explode=false, bad object',
      param_obj => { name => 'color', explode => false, schema => { type => 'object' } },
      queries => 'color=R,100,G,200,B',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
      skip_cookie => 1,
    },
    {
      name => 'explode=false, bad object, fall through to string',
      param_obj => { name => 'color', explode => false, schema => { type => [ qw(object string) ] } },
      queries => 'color=R,100,G,200,B',
      content => 'R,100,G,200,B',
      skip_cookie => 1,
    },
    {
      name => 'explode=false, bad object, requested array or object',
      param_obj => { name => 'color', explode => false, schema => { type => [qw(object array)] } },
      queries => 'color=R,100,G,200,B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'explode=false, prefer object',
      param_obj => { name => 'color', explode => false, schema => { type => [qw(object array)] } },
      queries => 'color=R,100,G,200,B,150&a=b&c=d',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'explode=false, object with non-string properties',
      param_obj => { name => 'color', explode => false, schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      queries => 'color=a,,b,0,c,42,d,100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'explode=true, object, no parameters',
      param_obj => { name => 'q', schema => { type => 'object' } },
      queries => '',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=true, object, no parameters, required',
      param_obj => { name => 'q', required => true, schema => { type => 'object' } },
      queries => '',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameters',
        },
      ],
    },
    {
      name => 'explode=true, empty object, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=&c=',
    },
    {
      name => 'explode=true, empty object, allowEmptyValue=true, required',
      param_obj => { name => 'q', allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q=&a=&c=',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameters',
        },
      ],
    },
    {
      name => 'explode=true, object, all empty string parameters, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=&c=',
      # content not extracted, but also no errors
    },
    {
      name => 'explode=true, object, some empty string parameters, allowEmptyValue=true',
      param_obj => { name => 'q', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=1&c=2',
      content => { a => '1', c => '2' },
    },
    {
      name => 'explode=true, object, missing named parameter',
      param_obj => { name => 'q', schema => { type => 'object' } },
      queries => 'a=b&c=d',
      content => { a => 'b', c => 'd' },
    },
    {
      name => 'explode=true, object, missing named parameter, required',
      param_obj => { name => 'q', required => true, schema => { type => 'object' } },
      queries => 'a=b&c=d',
      content => { a => 'b', c => 'd' },
    },
    {
      name => 'explode=true, object, missing all parameters, required',
      param_obj => { name => 'q', required => true, schema => { type => 'object' } },
      queries => '',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameters',
        },
      ],
    },
    {
      name => 'explode=true, object with non-string properties',
      param_obj => { name => 'color', schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      queries => 'a=&b=0&c=42&d=100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },

    # style=spaceDelimited

    [
      [ qw(style content queries) ],
      [ 'spaceDelimited', [], 'q' ],             # not reversible
      [ 'spaceDelimited', [], 'q=' ],
      [ 'spaceDelimited', [], 'q=&a=b&c=d' ],
      [ 'spaceDelimited', [ '', '', '' ], 'q=%20%20&a=b&c=d' ],
      [ 'spaceDelimited', [ '', '', '' ], 'q=%20%20' ],
      [ 'spaceDelimited', {}, 'q' ],             # not reversible
      [ 'spaceDelimited', {}, 'q=' ],
      [ 'spaceDelimited', {}, 'q=&a=b&c=d' ],
      [ 'spaceDelimited', { R => '', G => '', B => '' }, 'q=R%20%20G%20%20B%20' ],
      [ 'spaceDelimited', [ 'red' ], 'q=red' ],
      [ 'spaceDelimited', [ qw(blue black brown) ], 'q=blue%20black%20brown' ],
      [ 'spaceDelimited', { R => '', G => '', B => '' }, 'q=R%20%20G%20%20B%20' ],
      [ 'spaceDelimited', { R => '100', G => '200', B => '' }, 'q=R%20100%20G%20200%20B%20' ],
      [ 'spaceDelimited', { qw(R 100 G 200 B 150) }, 'q=R%20100%20G%20200%20B%20150' ],
      [ 'spaceDelimited', [ 'a+b' ], 'q=a%2Bb' ],
      [ 'spaceDelimited', [ 'a&b' ], 'q=a%26b' ],
      [ 'spaceDelimited', [ 'a#b' ], 'q=a%23b' ],
      [ 'spaceDelimited', [ 'a?b' ], 'q=a%3Fb' ],
      [ 'spaceDelimited', [ '100%' ], 'q=100%25' ],
      [ 'spaceDelimited', [ '100%25' ], 'q=100%2525' ],
      [ 'spaceDelimited', [ 'a+b', 'c' ], 'q=a%2Bb%20c' ],
      [ 'spaceDelimited', [ 'x=y', 'z' ], 'q=x%3Dy%20z' ],
      [ 'spaceDelimited', [ 'a&b', 'c' ], 'q=a%26b%20c' ],
    ],
    [
      [ qw(style name content queries) ],
      [ 'spaceDelimited', 'cølör', [ 'blue−black', 'black/ish﹠green', '100𝑥brown' ],
        'c%C3%B8l%C3%B6r=blue%E2%88%92black%20black%2Fish%EF%B9%A0green%20100%F0%9D%91%A5brown' ],
      [ 'spaceDelimited', 'cølör', { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
        'c%C3%B8l%C3%B6r=r%C3%A9d%20100%F0%9D%91%A5%20gr%C9%98%C9%87n%20%C2%A1ja%20bl%C3%B8%C3%B6%20%C2%BFne%C3%AEn&a=b&c=d' ],
    ],

    {
      name => 'no type is permitted',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { allOf => [ { type => 'array' }, { type => 'object' } ] } },
      queries => 'color=red',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'spaceDelimited style can only deserialize to arrays or objects',
        },
      ],
    },
    {
      name => 'primitive',
      param_obj => { name => 'color', style => 'spaceDelimited' },
      queries => 'color=blue&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'spaceDelimited style can only deserialize to arrays or objects',
        },
      ],
    },
    {
      name => 'array, missing',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => 'array' } },
      queries => 'a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'array, missing, required',
      param_obj => { name => 'q', style => 'spaceDelimited', required => true, schema => { type => 'array' } },
      queries => 'a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty array, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'spaceDelimited', allowEmptyValue => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'empty array, allowEmptyValue=true, required',
      param_obj => { name => 'q', style => 'spaceDelimited', allowEmptyValue => true, required => true, schema => { type => 'array' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty object, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'spaceDelimited', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
      # content not extracted, but also no errors
    },
    {
      name => 'empty object, allowEmptyValue=true, required',
      param_obj => { name => 'q', style => 'spaceDelimited', allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'wrong type, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'spaceDelimited', allowEmptyValue => true, schema => { type => 'string' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/q',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'spaceDelimited style can only deserialize to arrays or objects',
        },
      ],
    },
    {
      name => 'ask for array or object; object will fail',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => [ qw(array object) ] } },
      queries => 'color=R%20100%20G%20200%20B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'array with non-string items',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => {
          type => 'array',
          prefixItems => [
            { type => 'null' },
            { type => 'boolean' },
            { type => 'integer' },
            { type => 'string' },
          ],
        } },
      queries => 'color=%200%2042%20100',
      content => [ undef, false, 42, '100' ],
    },
    {
      name => 'explode=true, array',
      param_obj => { name => 'color', style => 'spaceDelimited', explode => true, schema => { type => 'array' } },
      queries => 'color=blue%20black%20brown&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path.'/explode',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/explode',
          error => 'explode=true is not supported for style=spaceDelimited',
        },
      ],
    },
    {
      name => 'bad object',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => 'object' } },
      queries => 'color=R%20100%20G%20200%20B',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'bad object, requested array or object',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => [qw(object array)] } },
      queries => 'color=R%20100%20G%20200%20B',
      content => [ qw(R 100 G 200 B) ],
    },
    {
      name => 'prefer object',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => [qw(object array)] } },
      queries => 'color=R%20100%20G%20200%20B%20150&a=b&c=d',
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'object with non-string properties',
      param_obj => { name => 'color', style => 'spaceDelimited',, schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      queries => 'color=a%20%20b%200%20c%2042%20d%20100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'object, malformed',
      param_obj => { name => 'color', style => 'spaceDelimited', schema => { type => 'object' } },
      queries => 'color=R%20100%20G%20200%20B&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'explode=true, object',
      param_obj => { name => 'color', style => 'spaceDelimited', explode => true, schema => { type => 'object' } },
      queries => 'color=R%20100%20G%20200%20B%20150&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path.'/explode',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/explode',
          error => 'explode=true is not supported for style=spaceDelimited',
        },
      ],
    },

    # style=pipeDelimited - cloned from spaceDelimited

    # style=deepObject

    [
      [ qw(style explode content queries) ],
      [ 'deepObject', true, { qw(R 100 G 200 B 150) }, 'q[R]=100&q[G]=200&q[B]=150' ],
      [ 'deepObject', true, { qw(R 100 G 200 B 150) }, 'q%5BR%5D=100&q%5BG%5D=200&q%5BB%5D=150' ],
      [ 'deepObject', true, { 'x+y' => 'a+b' }, 'q[x%2By]=a%2Bb' ],
      [ 'deepObject', true, { 'x+y' => 'a+b' }, 'q%5Bx%2By%5D=a%2Bb' ],
      [ 'deepObject', true, { 'x&y' => 'a&b' }, 'q[x%26y]=a%26b' ],
      [ 'deepObject', true, { 'x&y' => 'a&b' }, 'q%5Bx%26y%5D=a%26b' ],
      # '#' must always be escaped, as it marks the end of the query and start of the fragment
      [ 'deepObject', true, { 'x#y' => 'a#b' }, 'q%5Bx%23y%5D=a%23b' ],
      [ 'deepObject', true, { 'x?y' => 'a?b' }, 'q[x?y]=a?b' ],
      [ 'deepObject', true, { 'x?y' => 'a?b' }, 'q%5Bx%3Fy%5D=a%3Fb' ],
      # ']' cannot be used in a key name, but '[' can
      [ 'deepObject', true, { 'x[y' => 'a[b]' }, 'q[x%5By]=a[b]' ],
      [ 'deepObject', true, { 'x[y' => 'a[b]' }, 'q%5Bx%5By%5D=a%5Bb%5D' ],
      [ 'deepObject', true, { '100%' => '100%' }, 'q[100%25]=100%25' ],
      [ 'deepObject', true, { '100%' => '100%' }, 'q%5B100%25%5D=100%25' ],
      [ 'deepObject', true, { '100%25' => '100%25' }, 'q[100%2525]=100%2525' ],
      [ 'deepObject', true, { name => 'John Doe', email => 'john@example.com' },
        'q[name]=John%20Doe&q[email]=john%40example.com' ],
      [ 'deepObject', true, { R => '', G => '200', B => '' }, 'q[R]=&q[G]=200&q[B]=' ],
    ],

    {
      name => 'empty param names and values',
      param_obj => { name => '', style => 'deepObject', schema => { type => 'object' } },
      queries => 'color[R]=100&[]=&color[G]=200&color[B]=150&a[1]=b&c[2]=d',
      content => { '' => '' },
    },
    {
      name => 'object is not specified',
      param_obj => { name => 'color', style => 'deepObject', schema => { type => [qw(null number string array)] } },
      queries => 'color[red]=1&color[green]=2',
      errors => [
        {
          instanceLocation => '/request/uri/query/color',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'deepObject style can only deserialize to objects',
        },
      ],
    },
    {
      name => 'missing',
      param_obj => { name => 'q', style => 'deepObject', schema => { type => 'object' } },
      queries => 'floop[a]=1&floop[b]=2&a[1]=b&c[2]=d',
      # content not extracted, but also no errors
    },
    {
      name => 'missing, required',
      param_obj => { name => 'q', style => 'deepObject', required => true, schema => { type => 'object' } },
      queries => 'floop[a]=1&floop[b]=2&a[1]=b&c[2]=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'empty object, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q[a]=&a[x]=b&c[y]=d',
      # content not extracted, but also no errors
    },
    {
      name => 'empty object, allowEmptyValue=true, required',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q[a]=&a[x]=b&c[y]=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'some values are empty string, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q[a]=&q[b]=&q[c]=1&a[1]=b&c[2]=d',
      content => { c => '1' },
    },
    {
      name => 'all values are empty string, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, schema => { type => 'object' } },
      queries => 'q[a]=&q[b]=&a[1]=b&c[2]=d',
      # content not extracted, but also no errors
    },
    {
      name => 'empty string values, allowEmptyValue=true, required',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, required => true, schema => { type => 'object' } },
      queries => 'q[a]=&q[b]=&a[1]=b&c[2]=d',
      errors => [
        {
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing query parameter: q',
        },
      ],
    },
    {
      name => 'wrong type, allowEmptyValue=true',
      param_obj => { name => 'q', style => 'deepObject', allowEmptyValue => true, schema => { type => 'string' } },
      queries => 'q=&a=b&c=d',
      errors => [
        {
          instanceLocation => '/request/uri/query/q',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'deepObject style can only deserialize to objects',
        },
      ],
    },
    {
      name => 'object with non-string properties',
      param_obj => { name => 'color', style => 'deepObject', schema => {
          type => 'object',
          properties => {
            a => { type => 'null' },
            b => { type => 'boolean' },
            c => { type => 'integer' },
            d => { type => 'string' },
          },
        } },
      # "color[a]" => "", "color[b]" => 0, "color[c]" => 42, "color[d]" => 100
      queries => 'color%5Ba%5D=&color%5Bb%5D=0&color%5Bc%5D=42&color%5Bd%5D=100',
      content => { a => undef, b => false, c => 42, d => '100' },
    },
    {
      name => 'with encoded name and values',
      param_obj => { name => 'cølör', style => 'deepObject', schema => { type => 'object' } },
      queries => 'c%C3%B8l%C3%B6r%5Br%C3%A9d%5D=100%F0%9D%91%A5&c%C3%B8l%C3%B6r%5Bgr%C9%98%C9%87n%5D=%C2%A1ja&c%C3%B8l%C3%B6r%5Bbl%C3%B8%C3%B6%5D=%C2%BFne%C3%AEn&a%5B1%5D=b&c%5B2%5D=d',
      content => { 'réd' => '100𝑥', 'grɘɇn' => '¡ja', 'bløö' => '¿neîn' },
    },
  );

  # clone spaceDelimited tests to pipeDelimited; save a copy for cookie testing
  @query_tests = @tests = map +(
    (($_->{param_obj}{style}//'form') eq 'spaceDelimited' ? ($_, +{
    %$_,
    name => $_->{name} =~ s/spaceDelimited/pipeDelimited/r,
    param_obj => { $_->{param_obj}->%*, style => 'pipeDelimited' },
    queries => $_->{queries} =~ s/%20/%7C/gr,
    $_->{errors} ? (errors => [ map +{ %$_, error => $_->{error} =~ s/spaceDelimited/pipeDelimited/r }, $_->{errors}->@* ]) : (),
    }) : $_)
  ),

  map +(
    ref eq 'ARRAY'
      ? map +{
          name => defined $_->{explode} ? 'explode='.($_->{explode}?'true':'false') : '',
          param_obj => {
            name => $_->{name}//'q',
            style => $_->{style},
            defined $_->{explode} ? $_->%{explode} : (),
            schema => { type => get_type($_->{content}) },
            defined $_->{allowReserved} ? $_->%{allowReserved} : (),
          },
          $_->%{qw(queries content skip_cookie)},
        }, arrays_to_hashes($_)->@*
      : $_
  ), @tests;

  foreach my $test (@tests) {
    die 'missing test param "param_obj"' if not exists $test->{param_obj};
    die 'missing test param "queries"' if not exists $test->{queries};

    subtest 'query '
        .($test->{param_obj}{content} ? 'encoded with media-type' : 'style='.($test->{param_obj}{style}//'form'))
        .(length $test->{name} ? ', '.$test->{name} : '').': '
        .'"'.$test->{queries}.'"'.(exists $test->{content} ? ' -> '.$::dumper->encode($test->{content}) : '') => sub {

      my $param_obj = +{
        # default to type=string in the absence of an override
        exists $test->{param_obj}{content} ? () : (schema => { type => 'string' }),
        $test->{param_obj}->%*,
        in => 'query',
      };

      my $result = $openapi->evaluator->evaluate(
        $param_obj,
        OpenAPI::Modern::Utilities::DEFAULT_METASCHEMA()->{'3.2'}.'#/$defs/parameter',
      );
      fail('parameter object is valid'), note($result), return if not $result->valid;

      my $state = _init_test('/request/uri/query', +{ $param_obj->%{qw(schema content)} });

      my $valid = $openapi->_validate_parameter($state, $param_obj, params => Mojo::URL->new('https://example.com/blah?'.$test->{queries})->query);
      die 'validity inconsistent with error count; got valid=', 0+!!$valid, ', errors are: ',
        $::encoder->encode($state->{errors}) if $valid xor !$state->{errors}->@*;

      my $todo;
      $todo = todo $test->{todo} if $test->{todo};

      is_equal(
        [ map $_->TO_JSON, $state->{errors}->@* ],
        $test->{errors}//[],
        ($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred',
      );

      if (not exists $test->{content}) {
        ok(!keys $state->{data}->%*, 'no content was extracted')
          or note("extracted content:\n", $::encoder->encode($state->{data}));
      }
      else {
        ok(exists $state->{data}{request}{uri}{query}{$param_obj->{name}}, 'content was extracted');
        is_equal(
          $state->{data}{request}{uri}{query}{$param_obj->{name}},
          $test->{content},
          defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted',
        );
      }
    };
  }
};

subtest 'header parameters' => sub {
  my @tests = (
    # name (test name)
    # header_name
    # header_obj (from OAD)
    # raw header values (as an arrayref; one item per header line)
    # content => expected data that was parsed from serialized string; omit when nothing is to be found
    # errors => compared to what is collected from $state, defaults to []
    # todo
    {
      header_name => 'Accept',
      header_obj => {},
      values => [ 'application/json' ],
    },
    {
      header_name => 'Content-Type',
      header_obj => {},
      values => [ 'application/json' ],
    },
    {
      header_name => 'Authorization',
      header_obj => {},
      values => [ 'Basic whargarbl' ],
    },
    {
      name => 'encoded number',
      header_obj => { content => { 'application/json' => { schema => { type => 'integer' } } } },
      values => [ '3' ],
      content => 3, # number, not string!
    },
    {
      header_obj => { content => { 'application/json' => { schema => { type => 'string' } } } },
      values => [ "\"red\xef\xb9\xa0green\"" ],
      content => 'red﹠green',
    },
    {
      header_obj => { content => { 'application/json' => { schema => { type => 'string' } } } },
      values => [ 'ಠ_ಠ' ],
      errors => [
        {
          instanceLocation => '/response/header/My-Header',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'wide character detected in header value: not deserializable',
        },
      ],
    },

    # style=simple

    [
      # deserialized data, list of header strings
      [ qw(content values) ],
      [ undef, [''] ],
      [ false, [''] ],
      [ false, ['0'] ],
      [ true, ['1'] ],
      [ '', [''] ],
      [ 'i have spaces', [" i have spaces  \t "] ],
      [ 'foo,bar', [' foo ', ' bar '] ],         # leading/trailing whitespace is removed
      [ 'foo,  bar', [' foo,  bar '] ],          # for strings, internal ws is not not altered
      [ 'red﹠green', ["red\xef\xb9\xa0green"] ],
    ],
    [
      # explode, deserialized data, list of header strings
      [ qw(explode content values) ],
      [ false, ['foo'], ['foo'] ],  # a single header is passed as an array iff when array is requested
      [ true,  ['foo'], ['foo'] ],
      [ false, [ qw(foo bar) ], [' foo, bar '] ],   # split individual values on comma when type=array
      [ true,  [ qw(foo bar) ], [' foo, bar '] ],
      [ false, [ qw(foo bar baz) ], [' foo, bar ', ' baz '] ],
      [ true,  [ qw(foo bar baz) ], [' foo, bar ', ' baz '] ],
      [ false, [ qw(foo bar) ], [ ' foo ', ' bar ' ] ],  # ""
      [ false, [ qw(foo bar) ], [ ' foo, bar ' ] ],      # internal OWS is stripped for arrays
      [ false, [ 'blue−black', 'blackish﹠green', '100𝑥brown' ],
        [ "blue\xe2\x88\x92black,blackish\xef\xb9\xa0green,100\xf0\x9d\x91\xa5brown" ] ],
      [ true,  [ 'blue−black', 'blackish﹠green', '100𝑥brown' ],
        [ "blue\xe2\x88\x92black,blackish\xef\xb9\xa0green,100\xf0\x9d\x91\xa5brown" ] ],
      [ false, { qw(R 100 G 200 B 150) }, [' R, 100 ', ' G, 200, B, 150 '] ],
      [ true,  { qw(R 100 G 200 B 150) }, [' R=100, G=200 ', '  B=150 '] ],

      [ false, { 'foo=bar' => 'baz', bloop => '' },                [ 'foo=bar,baz,bloop,' ] ],
      [ true,  { foo => 'bar', baz => '', bloop => '', '' => '' }, [ 'foo=bar,baz,bloop,' ] ],
      [ false, { foo => 'bar=baz', bloop => '' },                  [ 'foo, bar=baz, bloop, ' ] ],
      [ false, { 'foo=bar' => 'baz', bloop => '' },                [ 'foo=bar, baz, bloop, ' ] ],
      [ true,  { foo => 'bar', baz => '', bloop => '', '' => '' }, [ 'foo=bar,baz,bloop, ' ] ],
      [ false, { foo => 'bar=baz', bloop => '' },                  [ 'foo,bar=baz,bloop,' ] ],
      [ true,  { foo => '', bar => 'baz', bloop => '', '' => '' }, [ 'foo,bar=baz,bloop,' ] ],
      [ false, { 'foo=bar=baz' => 'bloop' },                       [ 'foo=bar=baz, bloop' ] ],
      [ true,  { foo => 'bar=baz' => bloop => '' },                [ 'foo=bar=baz, bloop' ] ],
      [ false, { foo => 'bar', baz => '' },                        [ 'foo, bar, baz, ' ] ],
      [ true,  { foo => 'bar', baz => '' },                        [ 'foo=bar, baz' ] ],
      [ false, { foo => 'bar' },                                   [ ' foo ', ' bar ' ] ],
      [ false, { foo => 'bar' }, [ ' foo, bar ' ] ],     # internal OWS ws is stripped for objects

      [ false, { 'blue−black', 'yes!', 'blackish﹠green', '¿no?', '100𝑥brown', 'fl¡p' },
        [ "blue\xe2\x88\x92black,yes!,blackish\xef\xb9\xa0green,\xc2\xbfno?,100\xf0\x9d\x91\xa5brown,fl\xc2\xa1p" ] ],
      [ true,  { 'blue−black', 'yes!', 'blackish﹠green', '¿no?', '100𝑥brown', 'fl¡p' },
        [ "blue\xe2\x88\x92black=yes!,blackish\xef\xb9\xa0green=\xc2\xbfno?,100\xf0\x9d\x91\xa5brown=fl\xc2\xa1p" ] ],
    ],

    {
      name => 'missing but not required',
      header_obj => {},
      values => undef,
    },
    {
      name => 'missing, required',
      header_obj => { required => true },
      values => undef,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing header: My-Header',
        },
      ],
    },
    {
      header_obj => {},
      values => [ 'ಠ_ಠ' ],
      errors => [
        {
          instanceLocation => '/response/header/My-Header',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'wide character detected in header value: not deserializable',
        },
      ],
    },
    {
      name => 'array with numeric values',
      header_obj => { schema => { type => 'array', items => { type => 'number' } } },
      values => [ 'R,100,G,200,B,150' ],
      content => [ R => 100, G => 200, B => 150 ],
    },
    {
      name => 'object with numeric values, explode false',
      header_obj => { schema => { type => 'object', additionalProperties => { type => 'number' } } },
      values => [ 'R,100,G,200,B,150' ],
      content => { R => 100, G => 200, B => 150 },
    },
    {
      name => 'Object with numeric values, explode true',
      header_obj => { explode => true, schema => { type => 'object', additionalProperties => { type => 'number' } } },
      values => [ 'R=100,G=200,B=150' ],
      content => { R => 100, G => 200, B => 150 },
    },
    {
      name => 'object with missing , delimiter',
      header_obj => { explode => false, schema => { type => 'object' } },
      values => [ 'foo, bar, baz' ],
      errors => [
        {
          instanceLocation => '/response/header/My-Header',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'cannot deserialize to requested type (object)',
        },
      ],
    },
    {
      name => 'object with bad = delimiter',
      header_obj => { explode => true, schema => { type => 'object' } },
      values => [ 'foo=bar, baz=' ],
      errors => [
        {
          instanceLocation => '/response/header/My-Header',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'data does not match indicated style "simple" for object (invalid separator at key "baz")',
        },
      ],
    },
    {
      header_obj => {},
      values => [ "red\xef\xb9\xa0green" ],
      content => 'red﹠green',
    },
  );

  @tests = map +(
    ref eq 'ARRAY'
      ? map +{
          name => defined $_->{explode} ? 'explode='.($_->{explode}?'true':'false') : '',
          header_obj => {
            defined $_->{explode} ? $_->%{explode} : (),
            schema => { type => get_type($_->{content}) },
          },
          $_->%{qw(values content)},
        }, arrays_to_hashes($_)->@*
      : $_
  ), @tests;

  foreach my $test (@tests) {
    die 'missing test param "header_obj"' if not exists $test->{header_obj};
    die 'missing test param "values"' if not exists $test->{values};
    die 'bad test param "values"' if defined $test->{values} and ref $test->{values} ne 'ARRAY';

    subtest 'header '
        .($test->{header_obj}{content} ? 'encoded with media-type' : 'style=simple')
        .(length $test->{name} ? ', '.$test->{name}.': ' : ' ')
        .(defined $test->{values} ? $::dumper->encode($test->{values}) : '<missing>')
        .' -> '.$::dumper->encode($test->{content}) => sub {

      my $param_obj = +{
        name => $test->{header_name} // 'My-Header',
        exists $test->{header_obj}{content} ? () : (style => 'simple', schema => { type => 'string' }),
        $test->{header_obj}->%*,
        in => 'header',
      };

      my $result = $openapi->evaluator->evaluate(
        $param_obj,
        OpenAPI::Modern::Utilities::DEFAULT_METASCHEMA()->{'3.2'}.'#/$defs/parameter',
      );
      fail('parameter object is valid'), note($result), return if not $result->valid;

      my $header_obj = +{ %$param_obj };
      delete $header_obj->@{qw(in name)};

      $result = $openapi->evaluator->evaluate(
        $header_obj,
        OpenAPI::Modern::Utilities::DEFAULT_METASCHEMA()->{'3.2'}.'#/$defs/header',
      );
      fail('header object is valid'), note($result), return if not $result->valid;

      my $state = _init_test('/response/header', +{ $param_obj->%{qw(schema content)} });

      my $headers = Mojo::Headers->new;
      $headers->add(Encode::encode('UTF-8', $param_obj->{name}, Encode::DIE_ON_ERR | Encode::LEAVE_SRC), $test->{values}->@*)
        if defined $test->{values};

      my $valid = $openapi->_validate_parameter($state, $header_obj, $param_obj->%{name}, headers => $headers);
      die 'validity inconsistent with error count; got valid=', 0+!!$valid, ', errors are: ',
        $::encoder->encode($state->{errors}) if $valid xor !$state->{errors}->@*;

      my $todo;
      $todo = todo $test->{todo} if $test->{todo};

      is_equal(
        [ map $_->TO_JSON, $state->{errors}->@* ],
        $test->{errors}//[],
        ($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred',
      );

      if (not exists $test->{content}) {
        ok(!keys $state->{data}->%*, 'no content was extracted')
          or note("extracted content:\n", $::encoder->encode($state->{data}));
      }
      else {
        ok(exists $state->{data}{response}{header}{$param_obj->{name}}, 'content was extracted');
        is_equal(
          $state->{data}{response}{header}{$param_obj->{name}},
          $test->{content},
          defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted',
        );
      }
    };
  }
};

subtest 'cookie parameters' => sub {
  my @tests = (
    # name (test name)
    # param_obj (from OAD)
    # cookie => raw Cookie header string
    # content => expected data that was parsed from serialized string; omit when nothing is to be found
    # errors => compared to what is collected from $state, defaults to []
    # todo

    {
      name => 'missing header but not required',
      param_obj => { content => { 'application/json' => {} } },
    },
    {
      name => 'missing header, required',
      param_obj => { required => true, content => { 'text/plain' => {} } },
      errors => [
        {
          instanceLocation => '/request/header/Cookie',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing header: Cookie',
        },
      ],
    },
    {
      name => 'missing parameter but not required',
      param_obj => { name => 'q', content => { 'application/json' => {} } },
      cookie => 'foo=bar; baz=qux',
    },
    {
      name => 'missing parameter, required',
      param_obj => { name => 'q', required => true, content => { 'application/json' => {} } },
      cookie => 'foo=bar; baz=qux',
      errors => [
        {
          instanceLocation => '/request/header/Cookie',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing cookie parameter: q',
        },
      ],
    },
    {
      param_obj => { name => 'foo', content => { 'application/json' => {} } },
      cookie => 'foo=1',
      content => 1, # number, not string!
    },
    {
      name => 'adjacent to styled cookie parameters',
      param_obj => { name => 'color', content => { 'application/json' => {} } },
      cookie => 'foo=bar; color=1',
      content => 1,  # numeric value, carefully avoiding comma
    },
    {
      name => 'wide characters in cookie header (name)',
      param_obj => { name => 'ಠ_ಠ', content => { 'application/json' => { schema => { type => 'string' } } } },
      cookie => 'ಠ_ಠ=foo',
      errors => [
        {
          instanceLocation => '/request/header/Cookie/ಠ_ಠ',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'invalid cookie name: "ಠ_ಠ"',
        },
      ],
    },
    {
      name => 'wide characters in cookie header (value)',
      param_obj => { content => { 'application/json' => { schema => { type => 'string' } } } },
      cookie => 'q=ಠ_ಠ',
      errors => [
        {
          instanceLocation => '/request/header/Cookie/q',
          keywordLocation => $keyword_path,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
          error => 'invalid cookie value: "ಠ_ಠ"',
        },
      ],
    },

    (map +(
      {
        name => 'missing Cookie header but not required',
        param_obj => { style => $_ },
      },
      {
        name => 'missing Cookie header, required',
        param_obj => { style => $_, required => true },
        errors => [
          {
            instanceLocation => '/request/header/Cookie',
            keywordLocation => $keyword_path.'/required',
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
            error => 'missing header: Cookie',
          },
        ],
      },
      {
        name => 'missing cookie parameter but not required',
        param_obj => { style => $_ },
        cookie => 'foo=1&bar=2',
      },
      {
        name => 'missing cookie parameter, required',
        param_obj => { style => $_, required => true },
        cookie => 'foo=1&bar=2',
        errors => [
          {
            instanceLocation => '/request/header/Cookie',
            keywordLocation => $keyword_path.'/required',
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
            error => 'missing cookie parameter: q',
          },
        ],
      },
      {
        name => 'missing cookie-value',
        param_obj => { style => $_ },
        cookie => 'x',
        errors => [
          {
            instanceLocation => '/request/header/Cookie/x',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'cookie-string "x" is missing a value',
          },
        ],
      },
      {
        name => 'missing cookie-values',
        param_obj => { style => $_ },
        cookie => 'x; y',
        errors => [
          {
            instanceLocation => '/request/header/Cookie/x',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'cookie-string "x" is missing a value',
          },
          {
            instanceLocation => '/request/header/Cookie/y',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'cookie-string "y" is missing a value',
          },
        ],
      },
      {
        name => 'with boolean schema, return empty string as string',
        param_obj => { style => $_, schema => true },
        cookie => 'q=',
        content => '',
      },
      {
        name => 'with boolean schema, return data as string',
        param_obj => { style => $_, schema => true },
        cookie => 'q=42',
        content => '42',
      },
      {
        name => 'parameter name is valid even if not valid as a cookie name',
        param_obj => { name => 'q=hello', style => $_, schema => { type => 'object' } },
        cookie => 'q=hello=there',
        content => { q => 'hello=there' },
      },
      {
        name => 'invalid cookie name, but wrong name is parsed so value is not found',
        param_obj => { name => 'q=hello', style => $_, schema => { type => 'string' } },
        cookie => 'q=hello=there',
        # parsed as name = 'q', value = 'hello=there'
      },
      {
        name => 'invalid cookie name',
        param_obj => { name => 'foo[bar]', style => $_, schema => { type => 'string' } },
        cookie => 'foo[bar]=hi',
        errors => [
          {
            instanceLocation => '/request/header/Cookie/foo[bar]',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'invalid cookie name: "foo[bar]"',
          },
        ],
      },
      {
        name => 'invalid cookie values (bad character)',
        param_obj => { style => $_, schema => { type => 'string' } },
        cookie => 'foo=bad,value; bar=worse,value',
        errors => [
          {
            instanceLocation => '/request/header/Cookie/foo',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'invalid cookie value: "bad,value"',
          },
          {
            instanceLocation => '/request/header/Cookie/bar',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'invalid cookie value: "worse,value"',
          },
        ],
      },
      {
        name => 'invalid cookie values (mismatched quotes)',
        param_obj => { style => $_, schema => { type => 'string' } },
        cookie => 'foo=bad"',
        errors => [
          {
            instanceLocation => '/request/header/Cookie/foo',
            keywordLocation => $keyword_path,
            absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path,
            error => 'invalid cookie value: "bad\""',
          },
        ],
      },
    ), qw(form cookie)),

    # style=form - copied from query tests

    (map +(
      !exists $_->{param_obj}{content}
        && !$_->{param_obj}{allowEmptyValue}
        && (($_->{param_obj}//{})->{style}//'form') eq 'form'
      ? do {
        $_->{cookie} = delete $_->{queries};
        $_->{errors} = +[ map +{
          %$_,
          instanceLocation => $_->{instanceLocation} =~ s{uri/query}{header/Cookie}r,
          error => $_->{error} =~ s/query/cookie/r,
        }, $_->{errors}->@* ] if $_->{errors};
        $_;
      }
      : ()
    ), @query_tests),

    [
      [ qw(style content cookie) ],
      [ 'form', '', 'q=' ],
      [ 'form', 'red', '  q=red  ' ],
      [ 'form', '"red"', 'q="red"' ],
      [ 'form', '1', 'q=1&r=2&s=3' ],         # nonsensical if requesting a primitive, but still works
      [ 'form', '3', 'q=1; q=2; q=3' ],       # we take the last one when primitive is requested
      [ 'form', '1', 'q=1; r=2&s=3' ],
      [ 'form', '1', 'q=1; r=2; s=3' ],
    ],
    [
      [ qw(style name content cookie) ],
      [ 'form', 'cølör', 'blue/blåck', 'c%C3%B8l%C3%B6r=blue%2Fbl%C3%A5ck' ],
      [ 'form', 'cølör', 'blue/blåck', '%63%C3%B8%6C%C3%B6%72=blue%2Fbl%C3%A5ck' ],
    ],
    [
      [ qw(style explode content cookie) ],
      [ 'form', true,  [ '1' ], 'q=1' ],
      [ 'form', true,  [ '1' ], 'a=42; q=1; r=2; x=3' ],
      [ 'form', true,  [ qw(1 2) ], 'a=42; q=1&q=2; r=2; x=3' ],
      [ 'form', true,  { a => 'b', c => 'd' }, 'a=b&c=d' ],
    ],

    {
      name => 'multiple cookie entries with object',
      param_obj => { name => 'foo', schema => { type => 'object' } },
      cookie => 'a=b&c=d; foo=bar; foo=baz',
      # the content we really want is { a => 'b', c => 'd' }, not foo
      errors => [
        {
          instanceLocation => '/request/header/Cookie/foo',
          keywordLocation => $keyword_path.'/style',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/style',
          error => 'cannot deserialize into an object with style=form, explode=true when multiple cookies are present',
        },
      ],
    },

    # style=cookie

    {
      name => 'with boolean schema, return empty string as string',
      param_obj => { name => 'color', schema => true },
      cookie => 'color=',
      content => '',
    },
    {
      name => 'with boolean schema, return data as string',
      param_obj => { name => 'color', schema => true },
      cookie => 'color=42',
      content => '42',
    },
    [
      [ qw(style content cookie) ],
      [ 'cookie', undef, 'q=' ],
      [ 'cookie', false, 'q=' ],                     # not reversible
      [ 'cookie', false, 'q=0' ],
      [ 'cookie', true, 'q=1' ],
      [ 'cookie', false, 'q=false' ],                # not reversible
      [ 'cookie', true, 'q=true' ],                  # not reversible
      [ 'cookie', 0, 'q=0' ],
      [ 'cookie', 1, 'q=1' ],
      [ 'cookie', -42, 'q=-42' ],
      [ 'cookie', '', 'q=' ],
      [ 'cookie', 'red', 'q=red' ],
      [ 'cookie', 'red', '  q=red  ' ],              # not reversible
      [ 'cookie', '3', 'q=3' ],
      [ 'cookie', '3', 'q=1; q=2; q=3; a=1; b=2' ],  # not reversible
      [ 'cookie', '1', 'q=1; r=2&s=3' ],
      [ 'cookie', '1', 'q=1; r=2; s=3' ],
      [ 'cookie', 'a%2Bb', 'q=a%2Bb' ],
      [ 'cookie', 'a%26b', 'q=a%26b' ],
      [ 'cookie', 'a%23b', 'q=a%23b' ],
      [ 'cookie', 'a%3Fb', 'q=a%3Fb' ],
      [ 'cookie', '100%25', 'q=100%25' ],
      [ 'cookie', '100%2525', 'q=100%2525' ],
      [ 'cookie', 'x%3Dy', 'q=x%3Dy' ],
    ],
    [
      [ qw(style name content cookie) ],
      [ 'cookie', 'color', 'red-green', "color=red-green" ],
    ],
    [
      [ qw(style explode content cookie) ],
      [ 'cookie', true,  [''], 'q=' ],
      [ 'cookie', true,  [ '', '', '' ], 'q=; q=; q=' ],
      [ 'cookie', true,  [ qw(blue black brown) ], 'q=blue; q=black; q=brown' ],
      [ 'cookie', true,  { q => '' }, 'q=' ],
      [ 'cookie', true,  { R => '', G => '', B => '' }, 'R=; G=; B=' ],
      [ 'cookie', true,  { R => '100', G => '200', B => '' }, 'R=100; G=200; B=' ],
      [ 'cookie', true,  { qw(R 100 G 200 B 150) }, 'R=100; G=200; B=150' ],
    ],
  );

  @tests = map +(
    ref eq 'ARRAY'
      ? map +{
          name => defined $_->{explode} ? 'explode='.($_->{explode}?'true':'false') : '',
          param_obj => {
            name => $_->{name}//'q',
            style => $_->{style},
            defined $_->{explode} ? $_->%{explode} : (),
            schema => { type => get_type($_->{content}) },
          },
          $_->%{qw(cookie content)},
        }, arrays_to_hashes($_)->@*
      : $_
  ), @tests;

  foreach my $test (@tests) {
    die 'missing test param "param_obj"' if not exists $test->{param_obj};

    subtest 'cookie '
        .($test->{param_obj}{content} ? 'encoded with media-type' : 'style='.($test->{param_obj}{style}//'form'))
        .(length $test->{name} ? ', '.$test->{name} : '').': '
        .(defined $test->{cookie} ? '"'.$test->{cookie}.'"' : '<missing>')
        .' -> '.$::dumper->encode($test->{content}) => sub {

      skip_all 'not valid in cookie' if $test->{skip_cookie};

      my $param_obj = +{
        # default to type=string in the absence of an override
        exists $test->{param_obj}{content} ? () : (schema => { type => 'string' }),
        name => 'q',
        $test->{param_obj}->%*,
        in => 'cookie',
      };

      my $type = get_type($test->{content});
      skip_all "explode=false and $type not compatible with Cookie header"
        if not ($param_obj->{explode}//true) and ($type eq 'array' or $type eq 'object');

      my $result = $openapi->evaluator->evaluate(
        $param_obj,
        OpenAPI::Modern::Utilities::DEFAULT_METASCHEMA()->{'3.2'}.'#/$defs/parameter',
        { with_defaults => 1 },
      );
      fail('parameter object is valid'), note($result), return if not $result->valid;

      my $state = _init_test('/request/header/Cookie', +{ $param_obj->%{qw(schema content)} });

      my $headers = Mojo::Headers->new;
      $headers->add('Cookie', $test->{cookie}) if defined $test->{cookie};

      my $valid = $openapi->_validate_parameter($state, $param_obj, headers => $headers);
      die 'validity inconsistent with error count; got valid=', 0+!!$valid, ', errors are: ',
        $::encoder->encode($state->{errors}) if $valid xor !$state->{errors}->@*;

      my $todo;
      $todo = todo $test->{todo} if $test->{todo};

      is_equal(
        [ map $_->TO_JSON, $state->{errors}->@* ],
        $test->{errors}//[],
        ($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred',
      );

      if (not exists $test->{content}) {
        ok(!keys $state->{data}->%*, 'no content was extracted')
          or note("extracted content:\n", $::encoder->encode($state->{data}));
      }
      else {
        ok(exists $state->{data}{request}{header}{Cookie}{$param_obj->{name}}, 'content was extracted');
        is_equal(
          $state->{data}{request}{header}{Cookie}{$param_obj->{name}},
          $test->{content},
          defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted',
        );
      }
    };
  }
};

subtest 'type inference and coercion' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => 'http://localhost:1234/api',
    openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
components:
  parameters:
    MyParameter:
      name: my_parameter
      in: query
      schema: {}    # placeholder so fetching schema info will work
  schemas:
    my_type1:
      type: [ object, array ]
    my_type2:
      $ref: '#/components/schemas/my_type3'
    my_type3:
      allOf:
        - $ref: '#/components/schemas/my_type4'
        - $ref: '#/components/schemas/my_type5'
    my_type4:
      type: [ 'null', string ]
    my_type5:
      type: [ 'null', integer ]
    not_integer_3.0:
      not:
        $ref: https://example.com/my_3.0_oad#/components/schemas/integer
    not_integer_or_null_3.0:
      not:
        $ref: https://example.com/my_3.0_oad#/components/schemas/nullable_integer
    object_dynamicRef:
      $id: https://test.json-schema.org/typical-dynamic-resolution/object_root
      $ref: object_thing
      $defs:
        foo:
          $dynamicAnchor: more_object_thing      # final destination of the $dynamicRef
          type: object
          properties:
            b: { type: number }
        bar:
          $id: object_thing
          $dynamicRef: '#more_object_thing'
          unevaluatedProperties: { type: boolean }
          $defs:
            something:
              $comment: satisfy the bookending requirement
              $dynamicAnchor: more_object_thing
      properties:
        a: { type: boolean }
    object_of_mixed:
      type: object
      properties:
        a: { type: string }
        b: { type: [ number, string ] }
        c: { type: [ boolean, string ] }
        d: { type: [ 'null', string ] }
      patternProperties: { e: { type: boolean } }
      additionalProperties: { type: [ number, string ] }
    object_with_overlap:
      $ref: '#/components/schemas/object_of_mixed'
      properties:
        b: { type: number }
        c: { type: boolean }
        d: { type: string }
      additionalProperties: { type: number }
    object_with_unevaluatedProperties:
      type: object
      properties:
        a: { type: number }
        b: { type: number }
        d: { type: number }
      unevaluatedProperties:
        type: boolean
    object_with_allOf_and_unevaluatedProperties:
      type: object
      allOf:
        - properties:
            a: { type: [ number, string ] }
            b: { type: number }
            c: { type: boolean }
        - properties:
            a: { type: number }
            b: { type: number }
            d: { type: number }
      unevaluatedProperties:
        type: number
    object_of_numbers:
      type: object
      additionalProperties: { type: number }
    allOf_objects:
      type: object
      allOf:
        - properties: { a: { type: 'null' } }
        - properties: { b: { type: boolean } }
        - properties: { c: { type: integer } }
    array_dynamicRef:
      $id: https://test.json-schema.org/typical-dynamic-resolution/array_root
      $ref: array_thing
      $defs:
        foo:
          $dynamicAnchor: more_array_thing      # final destination of the $dynamicRef
          type: array
          prefixItems:
            - {}
            - { type: number }
        bar:
          $id: array_thing
          $dynamicRef: '#more_array_thing'
          unevaluatedProperties: { type: boolean }
          $defs:
            something:
              $comment: satisfy the bookending requirement
              $dynamicAnchor: more_array_thing
      prefixItems:
        - type: boolean
    array_of_mixed:
      type: array
      prefixItems:
        - { type: string }
        - { type: number }
        - { type: boolean }
        - { type: 'null' }
      items: { type: number }
    array_with_overlap:
      $ref: '#/components/schemas/array_of_mixed'
      prefixItems:
        - {}
        - { type: number }
        - { type: boolean }
        - { type: string }
      items: { type: number }
    array_with_unevaluatedItems:
      type: array
      prefixItems:
        - { type: number }
        - { type: number }
        - { type: number }
      unevaluatedItems:
        type: boolean
    array_with_allOf_and_unevaluatedItems:
      type: array
      allOf:
        - prefixItems:
            - { type: [ number, string ] }
            - { type: number }
            - { type: boolean }
        - prefixItems:
            - { type: number }
            - { type: number }
            - {}
            - { type: number }
      unevaluatedItems:
        type: number
    array_of_numbers:
      type: array
      items: { type: number }
    allOf_arrays:
      type: array
      allOf:
        - prefixItems:
          - { type: 'null' }
        - prefixItems:
          - true
          - { type: boolean }
        - prefixItems:
          - true
          - true
          - { type: integer }
YAML

  $openapi->evaluator->add_document(JSON::Schema::Modern::Document::OpenAPI->new(
    canonical_uri => 'https://example.com/my_3.0_oad',
    schema => my $schema_3_0 = decode_yaml(<<'YAML')));
openapi: 3.0.4
info:
  title: Test API
  version: 1.2.3
paths: {}
components:
  schemas:
    'true': {}
    ref_to_nullable_integer:
      $ref: '#/components/schemas/nullable_integer'
    integer:
      type: integer
    nullable_integer:
      type: integer
      nullable: true
    not_nullable_integer:
      type: integer
      nullable: false
    all_types: {}               # implies all types, null included
    nullable_without_type:
      nullable: true            # ""; "nullable" is ignored without "type"
    not_string:
      # note: implicit nullable=false at the root level
      not:
        type: string
    not_string_or_null:
      not:
        type: string
        nullable: true
YAML

  # the minimum necessary for _resolve_ref to work
  my $state = {
    initial_schema_uri => $openapi->openapi_uri,
    traversed_keyword_path => '',
    keyword_path => '/components/parameters/MyParameter/schema',
    data_path => '/request/uri/path',
    document => $openapi->openapi_document,
    ($openapi->openapi_document->_get_resource($openapi->openapi_document->canonical_uri)->%{qw(specification_version vocabularies)}),
    dynamic_scope => [ $openapi->openapi_uri ],
    evaluator => $openapi->evaluator,
    errors => [],
    depth => 0,
  };

  subtest 'type inference of an extracted parameter' => sub {
    foreach my $test (
      [ [ 'string' ], false ],
      [ [ qw(array object null boolean string number) ], true ],
      [ [ qw(array object boolean string number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/true' } ],
      [ [ qw(array object null boolean string number) ], {} ],
      (map [ [ $_ ], { type => $_ } ], qw(array object null boolean string number)),
      (map [ [ 'number' ], { type => $_ } ], qw(number integer)),
      [ [ qw(string null) ], { type => [qw(string null)] } ],
      [ [ 'object' ], { const => { R => 100, G => 200, B => 150 } } ],
      [ [ qw(number object) ], { enum => [ 10, { R => 100, G => 200, B => 150 } ] } ],
      [ [ 'string' ], { allOf => [ { type => 'string' }, { type => 'string' } ] } ],
      [ [ 'number' ], { allOf => [ { type => 'number' }, { type => 'integer' } ] } ],
      [ [], { allOf => [ { type => 'array' }, { type => 'string' } ] } ],
      [ [ qw(array string) ], { anyOf => [ { type => 'array' }, { type => 'string' } ] } ],
      [ [ qw(array string) ], { oneOf => [ { type => 'array' }, { type => 'string' } ] } ],
      [ [ qw(null boolean array) ], { not => { type => [ qw(string number object) ] } } ],
      [ [ 'object' ], { allOf => [ { type => 'object' }, { '$ref' => '#/components/schemas/my_type1' } ] } ],
      [ [ 'null' ], { '$ref' => '#/components/schemas/my_type2' } ],
      [ [ 'object' ], { '$ref' => '#/components/schemas/object_dynamicRef' } ],

      # 3.0 schemas ($ref comes from a 3.2 schema, which permits null)
      [ [ 'number' ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/integer' } ],
      [ [ qw(null number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/nullable_integer' } ],
      [ [ 'number' ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/not_nullable_integer' } ],
      [ [ qw(null number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/ref_to_nullable_integer' } ],
      [ [ qw(array object boolean string number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/all_types' } ],
      [ [ qw(array object boolean string number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/nullable_without_type' } ],
      [ [ qw(array object boolean number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/not_string' } ],
      [ [ qw(array object boolean number) ], { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/not_string_or_null' } ],
      [ [ qw(array object boolean string null) ], { '$ref' => '#/components/schemas/not_integer_3.0' } ],
      [ [ qw(array object boolean string) ], { '$ref' => '#/components/schemas/not_integer_or_null_3.0' } ],

      # $ref comes from a draft7 schema, which defers wholly to the $ref, ignoring all other keywords
      [ [ 'number' ], { '$schema' => 'http://json-schema.org/draft-07/schema#', allOf => [ { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/integer', type => 'object' } ] } ],
      [ [ qw(null number) ], { '$schema' => 'http://json-schema.org/draft-07/schema#', allOf => [ { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/nullable_integer', type => 'object' } ] } ],
      [ [ 'number' ], { '$schema' => 'http://json-schema.org/draft-07/schema#', allOf => [ { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/not_nullable_integer' }, type => 'object' ] } ],
      [ [ qw(null number) ], { '$schema' => 'http://json-schema.org/draft-07/schema#', allOf => [ { '$ref' => 'https://example.com/my_3.0_oad#/components/schemas/ref_to_nullable_integer', type => 'object' } ] } ],

    ) {
      my ($expected_types, $schema) = @$test;

      # hack, to allow _fetch_from_uri and cache to work
      jsonp_set($openapi->openapi_document->schema, $state->{keyword_path}, $schema);
      $openapi->openapi_document->{_type_in_schema} //= {};
      my $path = $state->{keyword_path};
      my $len = length $path;
      delete $openapi->openapi_document->{_type_in_schema}{$_}
        foreach grep substr($_, 0, $len) eq $path, keys $openapi->openapi_document->{_type_in_schema}->%*;

      my @types = $openapi->_type_in_schema($schema, { %$state });
      is_equal(
        [ sort @types], [ sort @$expected_types ],
            (is_bool($schema) ? 'schema is boolean'
          : 'schema has '.(!keys %$schema ? 'no keywords'
          : 'the keyword'.(keys %$schema > 1 ? 's' : '').' '.join(', ', keys %$schema)))
        .': got expected type'.(@$expected_types != 1 ? 's' : ''),
      )
      or note('with schema: ', $::encoder->encode($schema));
    }
  };

  subtest 'type coercion for primitives' => sub {
    foreach my $test (
      # ineligible data
      [ undef,    [qw(null boolean number string object array)] ],
      [ {},       [qw(null boolean number string object array)] ],
      [ [],       [qw(null boolean number string object array)] ],
      [ \'0',     [qw(null boolean number string object array)] ],
      [ \'1',     [qw(null boolean number string object array)] ],
      [ false,    [qw(null boolean number string object array)] ],
      [ true,     [qw(null boolean number string object array)] ],

      # valid coercions

      # note this may not be optimal for some usecases, e.g. path parameter
      [ '',       [qw(null boolean number string object array)], undef ],
      [ '',       [qw(boolean number string object array)], false ],
      [ '0',      [qw(boolean number string object array)], false ],
      [ '1',      [qw(boolean number string object array)], true ],
      [ 0,        [qw(boolean number string object array)], false ],
      [ 1,        [qw(boolean number string object array)], true ],
      [ 'false',  [qw(boolean number string object array)], false ],
      [ 'true',   [qw(boolean number string object array)], true ],
      [ '0',      [qw(null number string object array)], 0 ],
      [ '1',      [qw(null number string object array)], 1 ],
      [ '-42',    [qw(null boolean number string object array)], -42 ],
      [ '4e2',    [qw(null boolean number string object array)], 400 ],
      [ 20,       [qw(null boolean string object array)], '20' ],

      # no change
      [ 20,       ['boolean', 'number'], 20 ],
      [ 20,       [qw(null boolean number string object array)], 20 ],
      [ '20',     [qw(null boolean string object array)], '20' ],
      [ '',       [qw(number string object array)], '' ],
      [ 'hi',     ['string'], 'hi' ],
      [ 'hi',     [qw(null boolean number string object array)], 'hi' ],

    ) {
      my ($data, $types, $expected_data) = @$test;
      my $expected_type = @$test > 2 ? get_type($expected_data) : undef;

      subtest $expected_type ? 'coerce '.$::dumper->encode($data).' to ' .join(', ', @$types).'; want '.$expected_type
          : 'cannot coerce '.$::dumper->encode($data) => sub {
        my $valid = coerce_primitive(\$data, $types);

        if (defined $expected_type) {
          ok($valid, 'coercion was successful');
          ok(is_type($expected_type, $data), 'data was coerced to the correct type')
            or note 'got type: ', get_type($data);
          is($data, $expected_data, 'coerced data is perlishly correct');
          is_equal($data, $expected_data, 'coerced data is also more strictly correct')
            or note 'got type: ', get_type($data);
        }
        else {
          ok(!$valid, 'coercion was not successful');
        }
      };
    }
  };

  subtest 'type coercion for object properties and array items' => sub {
    my $idx = -1;
    foreach my $test (
      [ 'foo', {}, 'foo' ],
      [ 'foo', false, 'foo' ],
      [ 'foo', true, 'foo' ],
      [ { a => { b => 1 }, c => 2 }, { '$ref' => '#/components/schemas/object_of_mixed' }, { a => { b => 1 }, c => '2' } ],
      [ { a => '1', b => '2', c => '1', d => '', e => '5' }, { '$ref' => '#/components/schemas/object_of_mixed' },
        { a => '1', b => 2, c => true, d => undef, e => 5 } ],
      [ { a => '1', b => '2', c => '1', d => '', e => '5' }, { '$ref' => '#/components/schemas/object_with_overlap' },
        { a => '1', b => 2, c => true, d => '', e => 5 } ], # a has a conflict; left as string
      [ { qw(a 1 b 2 c 3 d 4 e 1) }, { '$ref' => '#/components/schemas/object_with_unevaluatedProperties' },
        { a => 1, b => 2, c => '3', d => 4, e => true } ],
      [ { qw(a 1 b 2 c 1 d 4 e 5) }, { '$ref' => '#/components/schemas/object_with_allOf_and_unevaluatedProperties' },
        { a => 1, b => 2, c => true, d => 4, e => 5 } ],
      [ { a => '1', b => '2', c => '1', d => '', e => 'a' }, { '$ref' => '#/components/schemas/object_of_numbers' },
        { a => 1, b => 2, c => 1, d => '', e => 'a' } ],
      [ { a => '', b => '1', c => '2' }, { '$ref' => '#/components/schemas/allOf_objects' },
        { a => undef, b => true, c => 2 } ],
      [ { a => '1', b => '2' }, { '$ref' => '#/components/schemas/object_dynamicRef' },
        { a => true, b => 2 } ],
    ) {
      my ($data, $schema, $expected_data, $errors) = @$test;
      $idx++;

      subtest $::dumper->encode($data) => sub {
        $openapi->_coerce_object_elements($data, $schema, { %$state, data_path => $state->{data_path}.'/'.$idx });

        is_equal(
          [ map $_->TO_JSON, $state->{errors}->@* ],
          $errors//[],
          ($errors//[])->@* ? 'the correct error was returned' : 'no errors occurred',
        );

        is_equal(
          $data,
          $expected_data,
          'got expected mutated data',
        ) if not (($errors//[])->@*);
      };
    }

    foreach my $test (
      [ 'foo', {}, 'foo' ],
      [ 'foo', false, 'foo' ],
      [ 'foo', true, 'foo' ],
      [ [ [ 1 ], 2 ], { '$ref' => '#/components/schemas/array_of_mixed' }, [ [ 1 ], 2 ] ],
      [ [ '1', '2', '1', '', '5' ], { '$ref' => '#/components/schemas/array_of_mixed' },
        [ '1', 2, true, undef, 5 ] ],
      [ [ '1', '2', '1', '', '5' ], { '$ref' => '#/components/schemas/array_with_overlap' },
        [ '1', 2, true, '', 5 ] ], # element 0 has conflict; left as string
      [ [ qw(1 2 3 4 1) ], { '$ref' => '#/components/schemas/array_with_unevaluatedItems' },
        [ 1, 2, 3, '4', true ] ],
      [ [ qw(1 2 1 4 5) ], { '$ref' => '#/components/schemas/array_with_allOf_and_unevaluatedItems' },
        [ 1, 2, true, 4, 5 ] ],
      [ [ '1', '2', '1', '', 'a' ], { '$ref' => '#/components/schemas/array_of_numbers' },
        [ 1, 2, 1, '', 'a' ] ],
      [ [ '', '1', '2' ], { '$ref' => '#/components/schemas/allOf_arrays' }, [ undef, true, 2 ] ],
      [ ['1', '2' ], { '$ref' => '#/components/schemas/array_dynamicRef' }, [ true, 2 ] ],
    ) {
      my ($data, $schema, $expected_data, $errors) = @$test;
      $idx++;

      subtest $::dumper->encode($data) => sub {
        $openapi->_coerce_array_elements($data, $schema, { %$state, data_path => $state->{data_path}.'/'.$idx });

        is_equal(
          [ map $_->TO_JSON, $state->{errors}->@* ],
          $errors//[],
          ($errors//[])->@* ? 'the correct error was returned' : 'no errors occurred',
        );

        is_equal(
          $data,
          $expected_data,
          'got expected mutated data',
        ) if not (($errors//[])->@*);
      };
    }
  };
};

done_testing;
