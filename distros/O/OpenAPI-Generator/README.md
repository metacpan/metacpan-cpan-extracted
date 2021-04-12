![linux](https://github.com/doojonio/OpenAPI-Generator/actions/workflows/linux-ci.yml/badge.svg)
# OpenAPI-Generator

Generate OpenAPI definitions from various places (currently only from plain old documentation)

# USAGE

Export OpenAPI from plain old documentation:

Perl modules (web controllers in some framework):

* Controllers/Controller1.pm:

	```
  package Controllers::Controller1;

  use strict;
  use warnings;

  =head1 NAME

    Controllers::Controller1;

  =head1 OPENAPI

  =over 2

  =item GET /api/request

    parameters:
      - $ref: "#/components/parameters/UserId"

  =cut

  sub hande_api_request { ... }

  =item POST /api/request

    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              username:
                type: string
    responses:
      "200":
        description: something

  =cut

  sub handle_api_request2 { ... }


  1

  __END__

  =item PARAM UserId

    name: id
    in: query
    schema:
      type: integer

  =item SECURITY ApiKey

    type: apiKey
    description: api key for my API
    name: x-Api-Key
    in: header

	```

* Controllers/Controller2.pm

	```
  package Controllers::Controller2;

  use strict;
  use warnings;

  =head1 NAME

    Controllers::Controller2;

  =head1 OPENAPI

  =over 2

  =item PUT /api/request

    parameters:
      - name: id
        in: query
        schema:
          type: integer
          minimum: 1
    requestBody:
      content:
        multipart/form-data:
          schema:
            type: object:
            properties:
              securityKey:
                type: string
    responses:
      "200":
        description: everything is ok
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/User"

  =cut

  sub hande_api_request { ... }

  =item POST /api/request2

    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              username:
                type: string
    responses:
      "200":
        description: something

  =cut

  sub handle_api_request2 { ... }

  =item SCHEMA User

    type: object
    properties:
      username:
        type: string

  =cut

  1

	```

In your script, which generates openapi file for you application:

```
#!/usr/bin/env perl
use strict;
use warnings;

use OpenAPI::Generator;
use YAML;

my $common_def = openapi_from(pod => {src => './Controllers'});
print YAML::Dump($common_def);

```

Will print:

```
---
components:
  parameters:
    UserId:
      in: query
      name: id
      schema:
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
  /api/request:
    get:
      parameters:
        - $ref: '#/components/parameters/UserId'
    post:
      requestBody:
        content:
          application/json:
            schema:
              properties:
                username:
                  type: string
              type: object
      responses:
        200:
          description: something
    put:
      parameters:
        - in: query
          name: id
          schema:
            minimum: 1
            type: integer
      requestBody:
        content:
          multipart/form-data:
            schema:
              properties:
                securityKey:
                  type: string
              type: 'object:'
      responses:
        200:
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
          description: everything is ok
  /api/request2:
    post:
      requestBody:
        content:
          application/json:
            schema:
              properties:
                username:
                  type: string
              type: object
      responses:
        200:
          description: something
```

# INSTALLATION

To install this module, run the following commands:

```
	perl Makefile.PL
	make
	make test
	make install
```

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

```
    perldoc OpenAPI::Generator
```

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Anton Fedotov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

