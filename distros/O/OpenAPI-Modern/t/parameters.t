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

use lib 't/lib';
use Helper;

my $openapi = OpenAPI::Modern->new(
  openapi_uri => 'http://localhost:1234/api',
  openapi_schema => {
    openapi => OAS_VERSION,
    info => { title => 'Test API', version => '1.2.3' },
    components => {
      schemas => {
        nothing => {},
        string => { type => 'string' },
        array => { type => 'array' },
        object => { type => 'object' },
        deep_string => { '$defs' => { foo => { type => 'string' } } },
        ref_to_deep_string => { '$ref' => '#/components/schemas/string' },
      },
    },
  },
);

$openapi->evaluator->add_schema({
  '$id' => 'http://localhost:1234/extras',
  '$defs' => {
    array => { type => 'array' },
    object => { type => 'object' },
    deep_string => { '$defs' => { foo => { type => 'string' } } },
    ref_to_deep_string => { '$ref' => 'api#/components/schemas/ref_to_deep_string' },
  },
});

my $parameter_content;
no warnings 'redefine';
*OpenAPI::Modern::_evaluate_subschema = sub ($, $dataref, $, $) {
  $parameter_content = $dataref->$*;
};

my $schema_path = '/paths/~1foo/get/parameters/0';

subtest 'path parameters' => sub {
  my @tests = (
    # param_obj
    # path_captures
    # content => data that was passed to _evaluate_subschema (expected)
    # errors => collected from state (expected), defaults to []
    # todo
    {
      param_obj => { name => 'missing', required => true, schema => false },
      path_captures => {},
      content => undef,
      errors => [
        {
          instanceLocation => '/request/path',
          keywordLocation => $schema_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$schema_path.'/required',
          error => 'missing path parameter: missing',
        },
      ],
    },
    # encoded with media-type
    {
      param_obj => { name => 'missing_json_content', in => 'path', content => { 'application/json' => { schema => { type => 'integer' } } } },
      path_captures => {},
      content => undef,
      errors => [
        {
          instanceLocation => '/request/path',
          keywordLocation => $schema_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$schema_path.'/required',
          error => 'missing path parameter: missing_json_content',
        },
      ],
    },
    {
      param_obj => { name => 'json_content', in => 'path', content => { 'application/json' => { schema => { type => 'integer' } } } },
      path_captures => { json_content => '3' },
      content => 3, # numeric, not string!
    },
    # style=simple
    {
      param_obj => { name => 'spaces', in => 'path', schema => false },
      path_captures => { spaces => " i have spaces  \t " },
      content => " i have spaces  \t ",
    },
    {
      param_obj => { name => 'single_value_false', in => 'path', schema => {} },
      path_captures => { single_value_false => 'foo' },
      content => 'foo',
    },
    {
      param_obj => { name => 'single_value_string', in => 'path', schema => { type => 'string' } },
      path_captures => { single_value_string => 'foo' },
      content => 'foo',
    },
    {
      # we do not normalize whitespace in path parameters
      param_obj => { name => 'comma_separated_string', in => 'path', schema => false },
      path_captures => { comma_separated_string => ' foo,  bar ' },
      content => ' foo,  bar ',
    },
    {
      # a single value is passed as an array iff when array is requested
      param_obj => { name => 'single_value_array', schema => { type => 'array' } },
      path_captures => { single_value_array => 'foo' },
      content => [ 'foo' ],
      todo => 'parse as array',
    },
    {
      # split individual values on comma when type=array; no space normalizing
      param_obj => { name => 'multiple_values_array', schema => { type => 'array' } },
      path_captures => { multiple_values_array => ' foo,  bar ' },
      content => [ ' foo', '  bar ' ],
      todo => 'parse as array',
    },
    {
      param_obj => { name => 'object_explode_false_spaces', explode => false, schema => { type => 'object' } },
      path_captures => { object_explode_false_spaces => ' R, 100 ,  B, 150,  G , 200 ' },
      content => { ' R' => ' 100 ', '  G ' => ' 200 ', '  B' => ' 150' },
      todo => 'parse as object',
    },
    {
      param_obj => { name => 'object_explode_false', explode => false, schema => { type => 'object', additionalProperties => { type => 'number' } } },
      path_captures => { object_explode_false => 'R,100,B,150,G,200' },
      content => { R => '100', G => '200', B => '150' },  # this can be validated as numbers
      todo => 'parse as object',
    },
    {
      param_obj => { name => 'object_explode_true_spaces', explode => true, schema => { type => 'object' } },
      path_captures => { object_explode_true_spaces => ' R= 100 ,  B= 150,  G = 200 ' },
      content => { ' R' => ' 100 ', '  G ' => ' 200 ', '  B' => ' 150' },
      todo => 'parse as object',
    },
    {
      param_obj => { name => 'object_explode_true', explode => true, schema => { type => 'object', additionalProperties => { type => 'number' } } },
      path_captures => { object_explode_true => 'R=100,B=150,G=200' },
      content => { R => '100', G => '200', B => '150' },  # this can be validated as numbers
      todo => 'parse as object',
    },
    # style=matrix
    {
      param_obj => { name => 'matrix_string_empty', style => 'matrix', schema => { type => 'string' } },
      path_captures => { matrix_string_empty => ';color' },
      content => '',
      todo => 'style=matrix',
    },
    {
      param_obj => { name => 'matrix_string', style => 'matrix', schema => { type => 'string' } },
      path_captures => { matrix_string => ';color=blue' },
      content => 'blue',
      todo => 'style=matrix',
    },
    {
      param_obj => { name => 'matrix_array_false', style => 'matrix', schema => { type => 'array' } },
      path_captures => { matrix_array_false => ';color=blue,black,brown' },
      content => [ qw(blue black brown) ],
      todo => 'style=matrix, parse as array',
    },
    {
      param_obj => { name => 'matrix_array_true', style => 'matrix', explode => true, schema => { type => 'array' } },
      path_captures => { matrix_array_true => ';color=blue;color=black;color=brown' },
      content => [ qw(blue black brown) ],
      todo => 'style=matrix, parse as array',
    },
    {
      param_obj => { name => 'matrix_object_false', style => 'matrix', schema => { type => 'object' } },
      path_captures => { matrix_object_false => ';color=R,100,G,200,B,150' },
      content => { R => '100', G => '200', B => '150' },
      todo => 'style=matrix, parse as object',
    },
    {
      param_obj => { name => 'matrix_object_true', style => 'matrix', explode => true, schema => { type => 'object' } },
      path_captures => { matrix_object_true => 'R=100;G=200;B=150' },
      content => { R => '100', G => '200', B => '150' },
      todo => 'style=matrix, parse as object',
    },
    # style=label
    {
      param_obj => { name => 'label_string_empty', style => 'label', schema => { type => 'string' } },
      path_captures => { label_string_empty => '.' },
      content => '',
      todo => 'style=label',
    },
    {
      param_obj => { name => 'label_string', style => 'label', schema => { type => 'string' } },
      path_captures => { label_string => '.blue' },
      content => 'blue',
      todo => 'style=label',
    },
    {
      param_obj => { name => 'label_array_false', style => 'label', schema => { type => 'array' } },
      path_captures => { label_array_false => '.blue,black,brown' },
      content => [ qw(blue black brown) ],
      todo => 'style=label, parse as array',
    },
    {
      param_obj => { name => 'label_array_true', style => 'label', explode => true, schema => { type => 'array' } },
      path_captures => { label_array_true => '.blue.black.brown' },
      content => [ qw(blue black brown) ],
      todo => 'style=label, parse as array',
    },
    {
      param_obj => { name => 'label_object_false', style => 'label', schema => { type => 'object' } },
      path_captures => { label_object_false => '.R,100,G,200,B,150' },
      content => { R => '100', G => '200', B => '150' },
      todo => 'style=label, parse as object',
    },
    {
      param_obj => { name => 'label_object_true', style => 'label', explode => true, schema => { type => 'object' } },
      path_captures => { label_object_true => '.R=100.G=200.B=150' },
      content => { R => '100', G => '200', B => '150' },
      todo => 'style=label, parse as object',
    },
  );

  TODO:
  foreach my $test (@tests) {
    undef $parameter_content;
    my $state = {
      initial_schema_uri => $openapi->openapi_uri,
      traversed_schema_path => '',
      schema_path => $schema_path,
      errors => [],
      depth => 0,
    };

    my $name = $test->{param_obj}{name};
    ()= $openapi->_validate_path_parameter({ %$state, data_path => '/request/path/'.$name },
      $test->{param_obj}, $test->{path_captures});

    local $TODO = $test->{todo} if $test->{todo};

    is_equal(
      [ map $_->TO_JSON, $state->{errors}->@* ],
      $test->{errors}//[],
      'path '.$name.': '.(($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred'),
    );

    is_equal(
      $parameter_content,
      $test->{content},
      'path '.$name.': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
    );
  }
};

subtest 'query parameters' => sub {
  my @tests = (
    # param_obj
    # queries => raw query string
    # content => data passed to _evaluate_subschema (expected)
    # errors => collected from state (expected), defaults to []
    # todo
    {
      param_obj => { name => 'reserved', in => 'query', allowEmptyValue => true, schema => false },
      queries => 'reserved=bloop',
      content => 'bloop', # parameter is validated as normal
      errors => [],
    },
    {
      param_obj => { name => 'reserved', in => 'query', allowEmptyValue => true, schema => false },
      queries => 'reserved=',
      content => undef, # empty parameter is not validated
      errors => [],
    },
    {
      param_obj => { name => 'missing_encoded_not_required', in => 'query', content => { 'application/json' => { schema => { type => 'object' } } } },
      queries => 'foo=1&bar=2',
      content => undef,
    },
    {
      param_obj => { name => 'missing_encoded_required', in => 'query', required => true, content => { 'application/json' => { schema => { type => 'object' } } } },
      queries => 'foo=1&bar=2',
      content => undef,
      errors => [
        {
          instanceLocation => '/request/query',
          keywordLocation => $schema_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$schema_path.'/required',
          error => 'missing query parameter: missing_encoded_required',
        },
      ],
    },
    {
      param_obj => { name => 'foo', in => 'query', content => { 'application/json' => { schema => { type => 'integer' } } } },
      queries => 'foo=1&bar=2',
      content => 1, # number, not string!
    },
    {
      param_obj => { name => 'reserved', in => 'query', allowReserved => true, schema => false },
      queries => 'reserved=!@$',
      content => undef,
      errors => [
        {
          instanceLocation => '/request/query/reserved',
          keywordLocation => $schema_path.'/allowReserved',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$schema_path.'/required',
          error => 'allowReserved: true is not yet supported',
        },
      ],
      todo => 'allowReserved not yet supported',
    },
    {
      param_obj => { name => 'color', in => 'query', schema => { type => 'integer' } },
      queries => 'R=100&G=200&B=150',
      content => undef,
    },
    {
      param_obj => { name => 'R', in => 'query', schema => { type => 'integer' } },
      queries => 'color=blue&R=100&G=200&B=150',
      content => '100',
    },
    { # form, string, empty
      param_obj => { name => 'color', schema => { type => 'string' } },
      queries => 'color=&R=100&G=200&B=150',
      content => '',
    },
    { # form, string
      param_obj => { name => 'color', schema => { type => 'string' } },
      queries => 'color=blue&R=100&G=200&B=150',
      content => 'blue',
    },
    { # form, array, false
      param_obj => { name => 'color', explode => false, schema => { type => 'string' } },
      queries => 'color=blue,black,brown&R=100&G=200&B=150',
      content => [ qw(blue black brown) ],
      todo => 'style=form, explode=false, parse as array',
    },
    { # form, array, true
      param_obj => { name => 'color', explode => true, schema => { type => 'array' } },
      queries => 'color=blue&color=black&color=brown&R=100&G=200&B=150',
      content => [ qw(blue black brown) ],
      todo => 'style=form, explode=true, parse as array',
    },
    { # form, object, false
      param_obj => { name => 'color', explode => false, required => true, schema => { type => 'object' } },
      queries => 'color=R,100,G,200,B,150&R=1&G=2&B=3',
      content => { R => '100', G => '200', B => '150' },
      todo => 'style=form, explode=false, parse as object',
    },
    { # form, object, true
      param_obj => { name => 'color', explode => true, required => true, schema => { type => 'object' } },
      queries => 'color=blue&R=100&G=200&B=150',
      content => { color => 'blue', R => '100', G => '200', B => '150' },
      todo => 'style=form, explode=true, parse as object',
    },

    # TODO:
    # spaceDelimited, string - not supported
    # spaceDelimited, array/object, true - not supported
    # spaceDelimited, array, false
    # spaceDelimited, object, false
    # pipeDelimited, string - not supported
    # pipeDelimited, array/object, true - not supported
    # pipeDelimited, array, false
    # pipeDelimited, object, false
    # deepObject, string - not supported
    # deepObject, array - not supported
    # deepObject, object, false - not supported
    # deepObject, object, true
  );

  TODO:
  foreach my $test (@tests) {
    undef $parameter_content;
    my $state = {
      initial_schema_uri => $openapi->openapi_uri,
      traversed_schema_path => '',
      schema_path => $schema_path,
      errors => [],
      depth => 0,
    };

    my $name = $test->{param_obj}{name};
    ()= $openapi->_validate_query_parameter({ %$state, data_path => '/request/query/'.$name },
      $test->{param_obj}, Mojo::URL->new('https://example.com/blah?'.$test->{queries}));

    local $TODO = $test->{todo} if $test->{todo};

    is_equal(
      [ map $_->TO_JSON, $state->{errors}->@* ],
      $test->{errors}//[],
      'query '.$name.' from '.$test->{queries}.': '.(($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred'),
    );

    is_equal(
      $parameter_content,
      $test->{content},
      'query '.$name.' from '.$test->{queries}.': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
    );
  }
};

subtest 'header parameters' => sub {
  my @tests = (
    # header name
    # header_obj
    # raw header values (as an arrayref; one item per header line)
    # content => data that was passed to _evaluate_subschema (expected)
    # errors => collected from state (expected), defaults to []
    # todo
    {
      name => 'Accept',
      header_obj => { schema => false },
      values => [ 'application/json' ],
      content => undef,
    },
    {
      name => 'Content-Type',
      header_obj => { schema => false },
      values => [ 'application/json' ],
      content => undef,
    },
    {
      name => 'Authorization',
      header_obj => { schema => false },
      values => [ 'Basic whargarbl' ],
      content => undef,
    },
    {
      name => 'Missing',
      header_obj => { required => true, schema => false },
      values => undef,
      content => undef,
      errors => [
        {
          instanceLocation => '/request/header',
          keywordLocation => $schema_path.'/required',,
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$schema_path.'/required',
          error => 'missing header: Missing',
        },
      ],
    },
    {
      name => 'Encoded-Number',
      header_obj => { content => { 'application/json' => { schema => { type => 'integer' } } } },
      values => [ '3' ],
      content => 3, # number, not string!
    },
    {
      name => 'Spaces',
      header_obj => { schema => false },
      values => [ " i have spaces  \t " ],
      content => 'i have spaces',
    },
    {
      name => 'Single-Header-False',
      header_obj => { schema => false },
      values => [ 'foo' ],
      content => 'foo',
    },
    {
      name => 'Single-Header-String',
      header_obj => { schema => { type => 'string' } },
      values => [ 'foo' ],
      content => 'foo',
    },
    {
      name => 'Single-Header-Deep-Ref-String',
      header_obj => { schema => { '$ref' => '#/components/schemas/ref_to_deep_string' } },
      values => [ 'foo' ],
      content => 'foo',
    },
    {
      name => 'Single-Header-Deep-Ref-Elsewhere-String',
      header_obj => { schema => { '$ref' => 'http://localhost:1234/extras#/$defs/ref_to_deep_string' } },
      values => [ 'foo' ],
      content => 'foo',
    },
    {
      # a single header is passed as an array iff when array is requested
      name => 'Single-Header-Array',
      header_obj => { schema => { type => 'array' } },
      values => [ 'foo' ],
      content => [ 'foo' ],
    },
    {
      name => 'Multiple-Headers-False',
      header_obj => { schema => false },
      values => [ ' foo ', '  bar  ' ],
      content => 'foo, bar',
    },
    {
      name => 'Multiple-Headers-String',
      header_obj => { schema => { type => 'string' } },
      values => [ ' foo ', ' bar ' ],
      content => 'foo, bar',
    },
    {
      # multiple headers are passed as an array iff when array is requested
      name => 'Multiple-Headers-Array',
      header_obj => { schema => { type => 'array' } },
      values => [ ' foo ', ' bar ' ],
      content => [ 'foo', 'bar' ],
    },
    {
      # internal comma-separated values are not altered
      name => 'Comma-Headers-String',
      header_obj => { schema => { type => 'string' } },
      values => [ ' foo,  bar ' ],
      content => 'foo,  bar',
    },
    {
      # split individual values on comma when type=array
      name => 'Comma-Headers-Array',
      header_obj => { schema => { type => 'array' } },
      values => [ ' foo,  bar ' ],
      content => [ 'foo', 'bar' ],
    },
    {
      name => 'Multi-Comma-Headers',
      header_obj => { schema => { type => 'array' } },
      values => [ ' foo,  bar ', ' baz ' ],
      content => [ 'foo', 'bar', 'baz' ],
    },
    {
      name => 'Object-Explode-False',
      header_obj => { explode => false, schema => { type => 'object' } },
      values => [ ' R, 100 ', ' B, 150,  G , 200 ' ],
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'Object-Explode-True',
      header_obj => { explode => true, schema => { type => 'object' } },
      values => [ ' R=100  , B=150 ', '  G=200 ' ],
      content => { R => '100', G => '200', B => '150' },
    },
    {
      name => 'Odd-Headers-Object',
      header_obj => { explode => false, schema => { type => 'object' } },
      values => [ 'foo, bar, baz' ],
      content => { foo => 'bar', baz => '' },
    },
  );

  TODO:
  foreach my $test (@tests) {
    undef $parameter_content;
    my $state = {
      initial_schema_uri => $openapi->openapi_uri,
      traversed_schema_path => '',
      schema_path => $schema_path,
      errors => [],
      depth => 0,
    };

    my $name = $test->{name};
    my $headers = Mojo::Headers->new;
    $headers->add($name, $test->{values}->@*) if defined $test->{values};

    my $exception = exception {
      ()= $openapi->_validate_header_parameter({ %$state, data_path => '/request/header/'.$name },
        $name, $test->{header_obj}, $headers);
    };

    local $TODO = $test->{todo} if $test->{todo};

    is($exception, undef, 'no exceptions');

    is_equal(
      [ map $_->TO_JSON, $state->{errors}->@* ],
      $test->{errors}//[],
      'header '.$name.': '.(($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred'),
    );

    is_equal(
      $parameter_content,
      $test->{content},
      'header '.$name.': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
    );
  }
};

done_testing;
