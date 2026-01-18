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
use JSON::Schema::Modern::Utilities qw(is_bool get_type);

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

my $openapi = OpenAPI::Modern->new(
  openapi_uri => 'http://localhost:1234/api',
  openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components: {}
YAML

my $parameter_content;
my $call_count = 0; # incremented when data is passed down for further processing
no warnings 'redefine';
*OpenAPI::Modern::_evaluate_subschema = sub ($, $dataref, $, $) {
  ++$call_count;
  $parameter_content = $dataref->$*;
  1;
};

my $keyword_path = '/paths/~1foo/get/parameters/0';

subtest 'path parameters' => sub {
  my @tests = (
    # param_obj
    # path_captures
    # content => data that was passed to _evaluate_subschema (expected)
    # errors => collected from state (expected), defaults to []
    # todo
    {
      param_obj => { name => 'missing', required => true },
      path_captures => {},
      content => undef,
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
      param_obj => { name => 'missing_json_content', in => 'path', content => { 'application/json' => { schema => { type => 'integer' } } } },
      path_captures => {},
      content => undef,
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
      param_obj => { name => 'json_content', in => 'path', content => { 'application/json' => { schema => { type => 'integer' } } } },
      path_captures => { json_content => '3' },
      content => 3, # numeric, not string!
    },
    # style=simple
    {
      param_obj => { name => 'no_type', in => 'path', schema => { maxLength => 3 } },
      path_captures => { no_type => 'R,100,G,200,B,150' },
      content => 'R,100,G,200,B,150',
    },
    {
      param_obj => { name => 'spaces', in => 'path' },
      path_captures => { spaces => " i have spaces  \t " },
      content => " i have spaces  \t ",
    },
    {
      param_obj => { name => 'single_value_false', in => 'path' },
      path_captures => { single_value_false => 'foo' },
      content => 'foo',
    },
    {
      param_obj => { name => 'single_value_number', in => 'path', schema => { type => 'number' } },
      path_captures => { single_value_number => '3' },
      content => 3,
    },
    {
      param_obj => { name => 'single_value_number_over_string', in => 'path', schema => { type => [ qw(string number) ] } },
      path_captures => { single_value_number_over_string => '3' },
      content => 3,
    },
    {
      param_obj => { name => 'single_value_string', in => 'path' },
      path_captures => { single_value_string => 'foo' },
      content => 'foo',
    },
    {
      # we do not normalize whitespace in path parameters
      param_obj => { name => 'comma_separated_string', in => 'path' },
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
      param_obj => { name => 'matrix_string_empty', style => 'matrix' },
      path_captures => { matrix_string_empty => ';color' },
      content => '',
      todo => 'style=matrix',
    },
    {
      param_obj => { name => 'matrix_string', style => 'matrix' },
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
      param_obj => { name => 'label_string_empty', style => 'label' },
      path_captures => { label_string_empty => '.' },
      content => '',
      todo => 'style=label',
    },
    {
      param_obj => { name => 'label_string', style => 'label' },
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

  foreach my $test (@tests) {
    my $param_obj = +{
      # default to type=string in the absence of an override
      exists $test->{param_obj}{content} ? () : (schema => { type => 'string' }),
      $test->{param_obj}->%*,
      in => 'path',
      required => true,
    };

    undef $parameter_content;
    my $state = {
      initial_schema_uri => $openapi->openapi_uri,
      traversed_keyword_path => '',
      keyword_path => $keyword_path,
      data_path => '/request',
      specification_version => 'draft2020-12',
      vocabularies => OAS_VOCABULARIES,
      errors => [],
      depth => 0,
    };

    my $name = $param_obj->{name};
    ()= $openapi->_validate_path_parameter($state, $param_obj, $test->{path_captures});

    todo_maybe($test->{todo}, sub {
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
    });
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
      param_obj => { name => 'reserved', in => 'query', allowEmptyValue => true },
      queries => 'reserved=bloop',
      content => 'bloop', # parameter is validated as normal
      errors => [],
    },
    {
      param_obj => { name => 'reserved', in => 'query', allowEmptyValue => true },
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
          instanceLocation => '/request/uri/query',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
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
      param_obj => { name => 'reserved', in => 'query', allowReserved => true },
      queries => 'reserved=!@$',
      content => undef,
      errors => [
        {
          instanceLocation => '/request/uri/query/reserved',
          keywordLocation => $keyword_path.'/allowReserved',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
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
      content => 100,
    },
    { # form, string, empty
      param_obj => { name => 'color' },
      queries => 'color=&R=100&G=200&B=150',
      content => '',
    },
    { # form, string
      param_obj => { name => 'color' },
      queries => 'color=20',
      content => '20',
    },
    { # form, number
      param_obj => { name => 'color', schema => { type => 'number' } },
      queries => 'color=20',
      content => 20,
    },
    { # form, number chosen over string
      param_obj => { name => 'color', schema => { type => [ qw(string number) ] } },
      queries => 'color=20',
      content => 20,
    },
    { # form, array, false
      param_obj => { name => 'color', explode => false },
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

  foreach my $test (@tests) {
    my $param_obj = +{
      # default to type=string in the absence of an override
      exists $test->{param_obj}{content} ? () : (schema => { type => 'string' }),
      $test->{param_obj}->%*,
      in => 'query',
    };

    undef $parameter_content;
    my $state = {
      initial_schema_uri => $openapi->openapi_uri,
      traversed_keyword_path => '',
      keyword_path => $keyword_path,
      data_path => '/request',
      specification_version => 'draft2020-12',
      vocabularies => OAS_VOCABULARIES,
      errors => [],
      depth => 0,
    };

    my $name = $param_obj->{name};
    ()= $openapi->_validate_query_parameter($state, $param_obj, Mojo::URL->new('https://example.com/blah?'.$test->{queries}));

    todo_maybe($test->{todo}, sub {
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
    });
  }
};

subtest 'header parameters' => sub {
  my @tests = (
    # name (header name, and test name)
    # header_obj (from OAD)
    # raw header values (as an arrayref; one item per header line)
    # content => expected data to be passed to _evaluate_subschema
    # errors => compared to what is collected from $state, defaults to []
    # todo
    {
      name => 'Accept',
      header_obj => {},
      values => [ 'application/json' ],
    },
    {
      name => 'Content-Type',
      header_obj => {},
      values => [ 'application/json' ],
    },
    {
      name => 'Authorization',
      header_obj => {},
      values => [ 'Basic whargarbl' ],
    },
    {
      name => 'Encoded-Number',
      header_obj => { content => { 'application/json' => { schema => { type => 'integer' } } } },
      values => [ '3' ],
      content => 3, # number, not string!
    },

    # style=simple

    # explode, deserialized data, list of header strings
    [ false, undef, [''] ],
    [ false, false, [''] ],
    [ false, false, ['0'] ],
    [ false, true, ['1'] ],
    [ false, '', [''] ],
    [ false, 'i have spaces', [" i have spaces  \t "] ],
    [ false, 'foo', ['foo'] ],
    [ false, ['foo'], ['foo'] ],  # a single header is passed as an array iff when array is requested
    [ false, 'foo,bar', [' foo ', ' bar '] ],
    [ false, 'foo,  bar', [' foo,  bar '] ],      # internal comma-separated values are not altered
    [ false, ['foo', 'bar'], [' foo,  bar '] ],   # split individual values on comma when type=array
    [ false, ['foo', 'bar', 'baz'], [' foo,  bar ', ' baz '] ],
    [ false, { qw(R 100 G 200 B 150) }, [' R, 100 ', ' G, 200,  B , 150 '] ],
    [ true,  { qw(R 100 G 200 B 150) }, [' R=100  , G=200 ', '  B=150 '] ],
    [ false, { foo => 'bar', baz => '' }, [ 'foo, bar, baz' ] ],
    [ true,  { foo => 'bar', baz => '' }, [ 'foo=bar, baz=' ] ],

    {
      name => 'Missing',
      header_obj => { required => true },
      values => undef,
      errors => [
        {
          instanceLocation => '/response/header',
          keywordLocation => $keyword_path.'/required',
          absoluteKeywordLocation => $openapi->openapi_uri.'#'.$keyword_path.'/required',
          error => 'missing header: Missing',
        },
      ],
    },
    {
      name => 'Array-with-numeric-values',
      header_obj => { schema => { type => 'array', items => { type => 'number' } } },
      values => [ 'R,100,G,200,B,150' ],
      content => [ R => 100, G => 200, B => 150 ],
    },
    {
      name => 'Object-with-numeric-values-explode-false',
      header_obj => { schema => { type => 'object', additionalProperties => { type => 'number' } } },
      values => [ 'R,100,G,200,B,150' ],
      content => { R => 100, G => 200, B => 150 },
    },
    {
      name => 'Object-with-numeric-values-explode-true',
      header_obj => { explode => true, schema => { type => 'object', additionalProperties => { type => 'number' } } },
      values => [ 'R=100,G=200,B=150' ],
      content => { R => 100, G => 200, B => 150 },
    },
  );

  foreach my $test (@tests) {
    $test = +{
      name => "style=simple, explode=".($test->[0]?'true':'false').': '.$::dumper->encode($test->[1]),
      header_obj => {
        style => 'simple',
        explode => $test->[0],
        schema => { type => get_type($test->[1]) },
      },
      values => $test->[2],
      content => $test->[1],
    } if ref $test eq 'ARRAY';

    subtest 'header '.$test->{name} => sub {
      my $param_obj = +{
        exists $test->{header_obj}{content} ? () : (schema => { type => 'string' }),
        $test->{header_obj}->%*,
        name => 'My-Header',
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

      undef $parameter_content;
      my $previous_call_count = $call_count;
      my $state = {
        initial_schema_uri => $openapi->openapi_uri,
        traversed_keyword_path => '',
        keyword_path => $keyword_path,
        data_path => '/response',
        specification_version => 'draft2020-12',
        vocabularies => OAS_VOCABULARIES,
        errors => [],
        depth => 0,
      };

      my $header_name = $test->{name} =~ /^[A-Z]/ ? $test->{name} : 'My-Header';
      my $headers = Mojo::Headers->new;
      $headers->add($header_name, $test->{values}->@*) if defined $test->{values};

      my $valid = $openapi->_validate_header_parameter($state, $header_name, $header_obj, $headers);
      die 'validity inconsistent with error count' if $valid xor !$state->{errors}->@*;

      my $todo;
      $todo = todo $test->{todo} if $test->{todo};

      if (not exists $test->{content}) {
        is($call_count, $previous_call_count, 'no content was extracted')
          or note("extracted content:\n", $::encoder->encode($parameter_content));
      }
      else {
        is($call_count, $previous_call_count+1, 'schema would be evaluated');
        is_equal(
          $parameter_content,
          $test->{content},
          'header '.$test->{name}.': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
        );
      }

      cmp_result(
        [ map $_->TO_JSON, $state->{errors}->@* ],
        $test->{errors}//[],
        'header '.$test->{name}.': '.(($test->{errors}//[])->@* ? 'the correct error was returned' : 'no errors occurred'),
      );
    };
  }
};

subtest 'type inference and coercion' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => 'http://localhost:1234/api',
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
components:
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
    schema => my $schema_3_0 = $yamlpp->load_string(<<'YAML')));
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
      [ [ qw(array object null boolean string number) ], false ],
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

      my @types = $openapi->_type_in_schema($schema, { %$state });
      cmp_result(
        [ sort @types], [ sort @$expected_types ],
            (is_bool($schema) ? 'schema is boolean'
          : 'schema has '.(!keys %$schema ? 'no keywords'
          : 'the keyword'.(keys %$schema > 1 ? 's' : '').' '.join(', ', keys %$schema)))
        .': got expected type'.(@$expected_types != 1 ? 's' : ''),
      )
      or note('with schema: ', $::encoder->encode($schema));
    }
  };

  subtest 'type coercion object properties and array items' => sub {
    my $idx = -1;
    foreach my $test (
      [ 'foo', {}, 'foo' ],
      [ 'foo', false, 'foo' ],
      [ 'foo', true, 'foo' ],
      [ { a => { b => 1 }, c => 2 }, { '$ref' => '#/components/schemas/object_of_mixed' }, { a => { b => 1 }, c => 2 } ],
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
          $data,
          $expected_data,
          'got expected mutated data',
        ) if not (($errors//[])->@*);

        is_equal(
          [ map $_->TO_JSON, $state->{errors}->@* ],
          $errors//[],
          ($errors//[])->@* ? 'the correct error was returned' : 'no errors occurred',
        );
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
          $data,
          $expected_data,
          'got expected mutated data',
        ) if not (($errors//[])->@*);

        is_equal(
          [ map $_->TO_JSON, $state->{errors}->@* ],
          $errors//[],
          ($errors//[])->@* ? 'the correct error was returned' : 'no errors occurred',
        );
      };
    }
  };
};

done_testing;
