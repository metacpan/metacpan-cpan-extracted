use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use lib 't/lib';
use Helper;

my $openapi_preamble = <<'YAML';
---
openapi: 3.1.0
info:
  title: Test API
  version: 1.2.3
YAML

my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'use discriminator to determine petType' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
  description: 'runtime: use discriminator to determine petType'
components:
  schemas:
    pet:
      discriminator:
        propertyName: petType
        mapping:
          fish: '#/components/schemas/definitions/\$defs/aquatic'
      anyOf:
      - \$ref: '#/components/schemas/cat'
      - \$ref: '#/components/schemas/definitions/\$defs/aquatic'

    cat:
      required: [ meow ]
      properties:
        petType:
          const: cat
        meow:
          const: true
    definitions:
      \$defs:
        aquatic:
          required: [ swims ]
          properties:
            petType:
              enum: [ fish, whale ]
            swims:
              const: true
YAML

  cmp_deeply(
    $openapi->evaluator->evaluate(
      { meow => true },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/discriminator',
          absoluteKeywordLocation => '/api#/components/schemas/pet/discriminator',
          error => 'missing required discriminator field "petType"',
        },
      ],
    },
    'missing required discriminator field "petType"',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      {
          petType => 'cat',
          meow => false,
      },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/meow',
          keywordLocation => '/anyOf/0/$ref/properties/meow/const',
          absoluteKeywordLocation => '/api#/components/schemas/cat/properties/meow/const',
          error => 'value does not match',
        },
        {
          instanceLocation => '/meow',
          keywordLocation => '/discriminator/propertyName/properties/meow/const',
          absoluteKeywordLocation => '/api#/components/schemas/cat/properties/meow/const',
          error => 'value does not match',
        },
      ),
    },
    'petType exists in /components/schemas/; false result',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      {
          petType => 'cat',
          meow => true,
      },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    { valid => true },
    'petType exists in /components/schemas/; true result',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      {
        petType => 'fish',
        swims => false,
      },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/swims',
          keywordLocation => '/anyOf/1/$ref/properties/swims/const',
          absoluteKeywordLocation => '/api#/components/schemas/definitions/$defs/aquatic/properties/swims/const',
          error => 'value does not match',
        },
        {
          instanceLocation => '/swims',
          keywordLocation => '/discriminator/mapping/fish/properties/swims/const',
          absoluteKeywordLocation => '/api#/components/schemas/definitions/$defs/aquatic/properties/swims/const',
          error => 'value does not match',
        },
      ),
    },
    'petType does not exist in /components/schemas/, but a mapping exists; false result',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      {
        petType => 'fish',
        swims => true,
      },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    { valid => true },
    'petType does not exist in /components/schemas/, but a mapping exists; true result',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      {
        petType => 'dog',
        barks => true,
      },
      Mojo::URL->new('/api#/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/petType',
          keywordLocation => '/discriminator',
          absoluteKeywordLocation => '/api#/components/schemas/pet/discriminator',
          error => 'invalid petType: "dog"',
        },
      ),
    },
    'no mapping for petType found',
  );
};

subtest 'discriminator in a parent definition' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => '/api',
    openapi_schema => $yamlpp->load_string(<<YAML));
$openapi_preamble
  description: 'runtime: use discriminator to determine petType'
components:
  schemas:
    petType:
      discriminator:
        propertyName: petType
        mapping:
          dog: Dog
    Pet:
      type: object
      required:
      - petType
      - sound
      properties:
        petType:
          type: string
    Cat:
      allOf:
      - \$ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Cat`
        properties:
          name:
            type: string
          sound:
            const: meow
    Dog:
      allOf:
      - \$ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Dog`
        properties:
          sound:
            const: bark
    dog:
      description: this is not the dog you're looking for
      allOf:
      - \$ref: '#/components/schemas/Pet'
      - type: object
        properties:
          sound:
            const: yipyip
    Lizard:
      allOf:
      - \$ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Lizard`
        properties:
          lovesRocks:
            type: boolean
          sound:
            const: 'null'
YAML

  cmp_deeply(
    $openapi->evaluator->evaluate(
      { petType => 'Cat', sound => 'meow' },
      Mojo::URL->new('/api#/components/schemas/petType'),
    )->TO_JSON,
    { valid => true },
    'discriminator can be defined in the base class',
  );

  cmp_deeply(
    $openapi->evaluator->evaluate(
      { petType => 'dog', sound => 'yipyip' },
      Mojo::URL->new('/api#/components/schemas/petType'),
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/sound',
          keywordLocation => '/discriminator/mapping/dog/allOf/1/properties/sound/const',
          absoluteKeywordLocation => '/api#/components/schemas/Dog/allOf/1/properties/sound/const',
          error => 'value does not match',
        },
        {
          instanceLocation => '',
          keywordLocation => '/discriminator/mapping/dog/allOf/1/properties',
          absoluteKeywordLocation => '/api#/components/schemas/Dog/allOf/1/properties',
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/discriminator/mapping/dog/allOf',
          absoluteKeywordLocation => '/api#/components/schemas/Dog/allOf',
          error => 'subschema 1 is not valid',
        },
      ],
    },
    'a mapping entry has precedence over defaulting to /components/schemas/{petType}',
  );
};

done_testing;
