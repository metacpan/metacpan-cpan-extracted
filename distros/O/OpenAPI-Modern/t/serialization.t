# vim: set ft=perl ts=8 sts=2 sw=2 tw=100 et :
use 5.020;
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

use Test::Needs qw(Sereal::Encoder Sereal::Decoder);
use lib 't/lib';
use Helper;
use Test2::Warnings qw(:no_end_test had_no_warnings allow_warnings);

# skip the END block which would normally try to print a plan
Test2::API::test2_stack->top->set_no_ending(1);

my $request = request('GET', 'https://example.com', [ 'Foo' => 'text/b,x' ]);

my $result_data = {
  valid => false,
  errors => [
    {
      instanceLocation => '/request/header/Foo',
      keywordLocation => '/paths/~1/parameters/0/schema/format',
      absoluteKeywordLocation => '/api#/paths/~1/parameters/0/schema/format',
      error => 'not a valid media-range string',
    },
  ],
};

# we fork before loading anything, including extra vocabularies
my ($pid, $child_stdin);

if ("$]" >= '5.022' or $^O ne 'MSWin32') {
  $pid = open($child_stdin, '|-');
  goto CHILD if $pid == 0;
}

my $openapi = OpenAPI::Modern->new(
  openapi_uri => '/api',
  openapi_schema => decode_yaml(OPENAPI_PREAMBLE.<<'YAML'));
paths:
  /:
    parameters:
      - name: Foo
        in: header
        required: true
        schema:
          type: string
          format: media-range
    get: {}
YAML

is_equal(
  $openapi->validate_request($request)->TO_JSON,
  $result_data,
  'request validation uses format definition',
);

my $frozen = Sereal::Encoder->new({ freeze_callbacks => 1 })->encode($openapi);
my $thawed = Sereal::Decoder->new->decode($frozen);

ok(
  exists(($thawed->evaluator->{_format_validations}//{})->{'media-range'}),
  'OpenAPI formats are re-loaded after thawing',
);

is_equal(
  $thawed->validate_request($request)->TO_JSON,
  $result_data,
  'request can still validate',
);

if ($child_stdin) {
  note 'now sending the frozen object to the child process for it to thaw...';

  print $child_stdin $frozen;
  close $child_stdin;

  my $hub = Test2::API::test2_stack->top;
  $hub->set_count($hub->count + 2 + ($ENV{AUTHOR_TESTING} ? 1 : 0));

  is(waitpid($pid, 0), -1, 'child process has finished');
}

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
exit 0;

CHILD: {
  my $hub = Test2::API::test2_stack->top;
  $hub->set_count(3);

  local $/;
  my $thawed = Sereal::Decoder->new->decode(<STDIN>);

  ok(
    exists(($thawed->evaluator->{_format_validations}//{})->{'media-range'}),
    'OpenAPI formats are re-loaded after thawing in a new process',
  );

  is_equal(
    $thawed->validate_request($request)->TO_JSON,
    $result_data,
    'request can still be validated after being thawed in a new process',
  );

  had_no_warnings() if $ENV{AUTHOR_TESTING};
}
