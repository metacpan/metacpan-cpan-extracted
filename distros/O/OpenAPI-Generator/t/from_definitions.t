#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin qw($RealBin);

use OpenAPI::Generator;
use CPAN::Meta::YAML qw(Load);

my $samples = "$RealBin/samples/FromDefinitions";

subtest 'with several definitions' => sub {
  my @additional_definitions = (
    {
      paths => {
        '/api/route4' => {
          'delete' => 'value4'
        }
      }
    }
  );
  my $expected = Load(<<'EOF');
paths:
  /api/route1:
    get: value1
  /api/route2:
    post: value2
  /api/route3:
    put: value3
  /api/route4:
    delete: value4
components:
  schemas:
    c1:
      key1: value1
    c2:
      key2: value2
    c3:
      key3: value3
  parameters:
    p1:
      key1: value1
    p2:
      key2: value2
    p3:
      key3: value3
  securitySchemes:
    s1:
      key1: value1
    s2:
      key2: value2
    s3:
      key3: value3
EOF

  my $got = openapi_from(definitions => {src => $samples, definitions => \@additional_definitions});

  is_deeply($got, $expected)
};

done_testing
