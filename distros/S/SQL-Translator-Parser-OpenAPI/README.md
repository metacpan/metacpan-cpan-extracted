# NAME

SQL::Translator::Parser::OpenAPI - convert OpenAPI schema to SQL::Translator schema

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/SQL-Translator-Parser-OpenAPI.svg?branch=master)](https://travis-ci.org/mohawk2/SQL-Translator-Parser-OpenAPI) |

[![CPAN version](https://badge.fury.io/pl/SQL-Translator-Parser-OpenAPI.svg)](https://metacpan.org/pod/SQL::Translator::Parser::OpenAPI) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/SQL-Translator-Parser-OpenAPI/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/SQL-Translator-Parser-OpenAPI?branch=master)

# SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Parser::OpenAPI;

    my $translator = SQL::Translator->new;
    $translator->parser("OpenAPI");
    $translator->producer("YAML");
    $translator->translate($file);

    # or...
    $ sqlt -f OpenAPI -t MySQL <my-openapi.json >my-mysqlschema.sql

# DESCRIPTION

This module implements a [SQL::Translator::Parser](https://metacpan.org/pod/SQL::Translator::Parser) to convert
a [JSON::Validator::OpenAPI](https://metacpan.org/pod/JSON::Validator::OpenAPI) specification to a [SQL::Translator::Schema](https://metacpan.org/pod/SQL::Translator::Schema).

It uses, from the given API spec, the given "definitions" to generate
tables in an RDBMS with suitable columns and types.

To try to make the data model represent the "real" data, it applies heuristics:

- to remove object definitions that only have one property
- to find object definitions that have all the same properties as another,
and remove all but the shortest-named one
- to remove object definitions whose properties are a strict subset
of another

# ARGUMENTS

None at present.

# PACKAGE FUNCTIONS

## parse

Standard as per [SQL::Translator::Parser](https://metacpan.org/pod/SQL::Translator::Parser). The input $data is a scalar
that can be understood as a [JSON::Validator
specification](https://metacpan.org/pod/JSON::Validator#schema).

# DEBUGGING

To debug, set environment variable `SQLTP_OPENAPI_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[SQL::Translator](https://metacpan.org/pod/SQL::Translator).

[SQL::Translator::Parser](https://metacpan.org/pod/SQL::Translator::Parser).

[JSON::Validator::OpenAPI](https://metacpan.org/pod/JSON::Validator::OpenAPI).
