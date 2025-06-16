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

my $doc_uri = Mojo::URL->new('http://example.com/api');
my $yamlpp = YAML::PP->new(boolean => 'JSON::PP');

subtest 'use discriminator to determine petType' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
  description: 'runtime: use discriminator to determine petType'
components:
  schemas:
    pet:
      discriminator:
        propertyName: petType
        mapping:
          fish: '#/components/schemas/definitions/$defs/aquatic'
      anyOf:
      - $ref: '#/components/schemas/cat'
      - $ref: '#/components/schemas/definitions/$defs/aquatic'

    cat:
      required: [ meow ]
      properties:
        petType:
          const: cat
        meow:
          const: true
    definitions:
      $defs:
        aquatic:
          required: [ swims ]
          properties:
            petType:
              enum: [ fish, whale ]
            swims:
              const: true
YAML

  cmp_result(
    $openapi->evaluator->evaluate(
      { meow => true },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '',
          keywordLocation => '/discriminator',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/pet/discriminator')->to_string,
          error => 'missing required discriminator property "petType"',
        },
      ],
    },
    'missing required discriminator property "petType"',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      {
          petType => 'cat',
          meow => false,
      },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/meow',
          keywordLocation => '/anyOf/0/$ref/properties/meow/const',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/cat/properties/meow/const')->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/meow',
          keywordLocation => '/discriminator/propertyName/properties/meow/const',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/cat/properties/meow/const')->to_string,
          error => 'value does not match',
        },
      ),
    },
    'petType exists in /components/schemas/; false result',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      {
          petType => 'cat',
          meow => true,
      },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    { valid => true },
    'petType exists in /components/schemas/; true result',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      {
        petType => 'fish',
        swims => false,
      },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/swims',
          keywordLocation => '/anyOf/1/$ref/properties/swims/const',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/definitions/$defs/aquatic/properties/swims/const')->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '/swims',
          keywordLocation => '/discriminator/mapping/fish/properties/swims/const',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/definitions/$defs/aquatic/properties/swims/const')->to_string,
          error => 'value does not match',
        },
      ),
    },
    'petType does not exist in /components/schemas/, but a mapping exists; false result',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      {
        petType => 'fish',
        swims => true,
      },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    { valid => true },
    'petType does not exist in /components/schemas/, but a mapping exists; true result',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      {
        petType => 'dog',
        barks => true,
      },
      $doc_uri->clone->fragment('/components/schemas/pet'),
    )->TO_JSON,
    {
      valid => false,
      errors => superbagof(
        {
          instanceLocation => '/petType',
          keywordLocation => '/discriminator',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/pet/discriminator')->to_string,
          error => 'invalid petType: "dog"',
        },
      ),
    },
    'no mapping for petType found',
  );
};

subtest 'discriminator in a parent definition' => sub {
  my $openapi = OpenAPI::Modern->new(
    openapi_uri => $doc_uri,
    openapi_schema => $yamlpp->load_string(OPENAPI_PREAMBLE.<<'YAML'));
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
      - $ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Cat`
        properties:
          name:
            type: string
          sound:
            const: meow
    Dog:
      allOf:
      - $ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Dog`
        properties:
          sound:
            const: bark
    dog:
      description: this is not the dog you're looking for
      allOf:
      - $ref: '#/components/schemas/Pet'
      - type: object
        properties:
          sound:
            const: yipyip
    Lizard:
      allOf:
      - $ref: '#/components/schemas/Pet'
      - type: object
        # all other properties specific to a `Lizard`
        properties:
          lovesRocks:
            type: boolean
          sound:
            const: 'null'
YAML

  cmp_result(
    $openapi->evaluator->evaluate(
      { petType => 'Cat', sound => 'meow' },
      $doc_uri->clone->fragment('/components/schemas/petType'),
    )->TO_JSON,
    { valid => true },
    'discriminator can be defined in the base class',
  );

  cmp_result(
    $openapi->evaluator->evaluate(
      { petType => 'dog', sound => 'yipyip' },
      $doc_uri->clone->fragment('/components/schemas/petType'),
    )->TO_JSON,
    {
      valid => false,
      errors => [
        {
          instanceLocation => '/sound',
          keywordLocation => '/discriminator/mapping/dog/allOf/1/properties/sound/const',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/Dog/allOf/1/properties/sound/const')->to_string,
          error => 'value does not match',
        },
        {
          instanceLocation => '',
          keywordLocation => '/discriminator/mapping/dog/allOf/1/properties',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/Dog/allOf/1/properties')->to_string,
          error => 'not all properties are valid',
        },
        {
          instanceLocation => '',
          keywordLocation => '/discriminator/mapping/dog/allOf',
          absoluteKeywordLocation => $doc_uri->clone->fragment('/components/schemas/Dog/allOf')->to_string,
          error => 'subschema 1 is not valid',
        },
      ],
    },
    'a mapping entry has precedence over defaulting to /components/schemas/{petType}',
  );
};

done_testing;
