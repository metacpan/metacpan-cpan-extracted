#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin qw($RealBin);

use OpenAPI::Generator;

use CPAN::Meta::YAML qw(Load);

my $samples = "$RealBin/samples/FromPod";

# - - -
subtest 'check single file' => sub {

  my $got = openapi_from(pod => {src => "$samples/Controller.pod"});
  my $expected = Load(<<'EOF');
---
components:
  parameters:
    UserId:
      in: query
      name: id
      schema:
        minimum: 1
        type: integer
  schemas:
    User:
      properties:
        username:
          type: string
      type: object
  securitySchemes:
    ApiKey:
      description: api key for my API
      in: header
      name: x-Api-Key
      type: apiKey
paths:
  /api/route:
    get:
      parameters:
        - in: query
          name: productId
          schema:
            type: integer
        - $ref: '#/components/parameters/UserId'
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response
  /api/route2:
    get:
      parameters:
        - in: query
          name: id
          schema:
            type: integer
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response

EOF

  is_deeply($got, $expected);
};
# - - -

subtest check_directory => sub {
  my $got = openapi_from(pod => {src => $samples});
  my $expected = Load(<<'EOF');
---
components:
  parameters:
    TaskId:
      in: query
      name: id
      schema:
        minimum: 1
        type: integer
    UserId:
      in: query
      name: id
      schema:
        minimum: 1
        type: integer
  schemas:
    ProductInfo:
      properties:
        cost:
          type: number
        name:
          type: string
      type: object
    User:
      properties:
        username:
          type: string
      type: object
  securitySchemes:
    ApiKey:
      description: api key for my API
      in: header
      name: x-Api-Key
      type: apiKey
    Cookie:
      description: Cookie auth
      in: cookie
      name: auth
      scheme:
        type: string
      type: http
paths:
  /api/route:
    get:
      parameters:
        - in: query
          name: productId
          schema:
            type: integer
        - $ref: '#/components/parameters/UserId'
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response
  /api/route2:
    get:
      parameters:
        - in: query
          name: id
          schema:
            type: integer
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response
    put:
      parameters:
        - in: query
          name: id
          schema:
            type: integer
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response
  /api/route3:
    post:
      parameters:
        - in: query
          name: productId
          schema:
            type: integer
        - $ref: '#/components/parameters/TaskId'
      requestBody:
        content:
          application/json:
            schema:
              items:
                type: number
              type: array
      responses:
        200:
          description: response

EOF

  is_deeply($got, $expected);
};

subtest check_file_with_no_pod => sub {

  my $res = openapi_from(pod => {src => "$samples/Empty.pm"});
  is $res, undef, 'nothing has been generated';
};

done_testing
