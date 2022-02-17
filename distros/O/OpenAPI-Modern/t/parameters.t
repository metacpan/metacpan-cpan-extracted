use strict;
use warnings;
use strictures 2;
use experimental qw(signatures postderef);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use OpenAPI::Modern;
use URI;
use Test::File::ShareDir -share => { -dist => { 'OpenAPI-Modern' => 'share' } };
use constant { true => JSON::PP::true, false => JSON::PP::false };

my $openapi = OpenAPI::Modern->new(
  openapi_uri => 'openapi.yaml',
  openapi_schema => {
    openapi => '3.1.0',
    info => { title => 'Test API', version => '1.2.3' },
    paths => {},
  },
);

my $parameter_content;
no warnings 'redefine';
*OpenAPI::Modern::_validate_parameter_content = sub ($, $, $, $data_ref) {
  $parameter_content = $data_ref->$*;
};

subtest 'query parameters' => sub {
  my $state = {
    initial_schema_uri => Mojo::URL->new,
    traversed_schema_path => '',
    schema_path => '/paths/~1foo/get/parameters/0',
    errors => [],
  };

  my @tests = (
    # param_obj
    # raw query string,
    # content => extracted data passed to _validate_parameter_content
    # errors => from state
    { param_obj => { name => 'reserved', in => 'query', allowReserved => true, schema => false },
      queries => 'reserved=',
      content => undef,
      errors => [
        {
          instanceLocation => '/request/query/reserved',
          keywordLocation => $state->{schema_path}.'/allowReserved',
          error => 'allowReserved: true is not yet supported',
        },
      ],
    },
  );

  foreach my $test (@tests) {
    undef $parameter_content;
    my $name = $test->{param_obj}{name};
    ()= $openapi->_validate_query_parameter({ %$state, data_path => '/request/query/'.$name },
      $test->{param_obj}, URI->new('https://example.com/blah?'.$test->{queries}));

    cmp_deeply(
      [ map $_->TO_JSON, $state->{errors}->@* ],
      $test->{errors},
      'header '.$name.': '.($test->{errors}->@* ? 'the correct error was returned' : 'no errors occurred'),
    );
    cmp_deeply(
      $parameter_content,
      $test->{content},
      'header '.$name.': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
    );
  }
};

subtest 'header parameters' => sub {
  my $state = {
    initial_schema_uri => Mojo::URL->new,
    traversed_schema_path => '',
    schema_path => '/paths/~1foo/get/parameters/0',
    errors => [],
  };

  my @tests = (
    # args => [ header_name, header_obj, headers (values) ]
    # content => extracted data passed to _validate_parameter_content
    # errors => from state
    { args => [ 'Accept', { schema => false }, [ 'application/json' ] ], content => undef, errors => [] },
    { args => [ 'Content-Type', { schema => false }, [ 'application/json' ] ], content => undef, errors => [] },
    { args => [ 'Authorization', { schema => false }, [ 'Basic whargarbl' ] ], content => undef, errors => [] },
    { args => [ 'Spaces', { schema => false }, [ " i have spaces  \t " ] ], content => 'i have spaces', errors => [] },
  );

  foreach my $test (@tests) {
    undef $parameter_content;
    ()= $openapi->_validate_header_parameter({ %$state, data_path => '/request/header/'.$test->{args}[0] },
      $test->{args}->@*);

    cmp_deeply(
      [ map $_->TO_JSON, $state->{errors}->@* ],
      $test->{errors},
      'header '.$test->{args}[0].': '.($test->{errors}->@* ? 'the correct error was returned' : 'no errors occurred'),
    );
    cmp_deeply(
      $parameter_content,
      $test->{content},
      'header '.$test->{args}[0].': '.(defined $test->{content} ? 'the correct content was extracted' : 'no content was extracted'),
    );
  }
};

done_testing;
