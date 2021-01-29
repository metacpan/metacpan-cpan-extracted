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

    # or, applying an overlay:
    $ perl -MHash::Merge=merge -Mojo \
      -e 'print j merge map j(f($_)->slurp), @ARGV' \
        t/06-corpus.json t/06-corpus.json.overlay |
      sqlt -f OpenAPI -t MySQL >my-mysqlschema.sql

# DESCRIPTION

This module implements a [SQL::Translator::Parser](https://metacpan.org/pod/SQL%3A%3ATranslator%3A%3AParser) to convert
a [JSON::Validator::OpenAPI::Mojolicious](https://metacpan.org/pod/JSON%3A%3AValidator%3A%3AOpenAPI%3A%3AMojolicious) specification to a [SQL::Translator::Schema](https://metacpan.org/pod/SQL%3A%3ATranslator%3A%3ASchema).

It uses, from the given API spec, the given "definitions" to generate
tables in an RDBMS with suitable columns and types.

To try to make the data model represent the "real" data, it applies heuristics:

- to remove object definitions considered non-fundamental; see
["definitions\_non\_fundamental"](#definitions_non_fundamental).
- for definitions that have `allOf`, either merge them together if there
is a `discriminator`, or absorb properties from referred definitions
- creates object definitions for any properties that are an object
- creates object definitions for any properties that are an array of simple
OpenAPI types (e.g. `string`)
- creates object definitions for any objects that are
`additionalProperties` (i.e. freeform key/value pairs), that are
key/value rows
- absorbs any definitions that are in fact not objects, into the referring
property
- injects foreign-key relationships for array-of-object properties, and
creates many-to-many tables for any two-way array relationships

# ARGUMENTS

## snake\_case

If true, will create table names that are not the definition names, but
instead the pluralised snake\_case version, in line with SQL convention. By
default, the tables will be named after simply the definitions.

# PACKAGE FUNCTIONS

## parse

Standard as per [SQL::Translator::Parser](https://metacpan.org/pod/SQL%3A%3ATranslator%3A%3AParser). The input $data is a scalar
that can be understood as a [JSON::Validator
specification](https://metacpan.org/pod/JSON%3A%3AValidator#schema).

## defs2mask

Given a hashref that is a JSON pointer to an OpenAPI spec's
`/definitions`, returns a hashref that maps each definition name to a
bitmask. The bitmask is set from each property name in that definition,
according to its order in the complete sorted list of all property names
in the definitions. Not exported. E.g.

    # properties:
    my $defs = {
      d1 => {
        properties => {
          p1 => 'string',
          p2 => 'string',
        },
      },
      d2 => {
        properties => {
          p2 => 'string',
          p3 => 'string',
        },
      },
    };
    my $mask = SQL::Translator::Parser::OpenAPI::defs2mask($defs);
    # all prop names, sorted: qw(p1 p2 p3)
    # $mask:
    {
      d1 => (1 << 0) | (1 << 1),
      d2 => (1 << 1) | (1 << 2),
    }

## definitions\_non\_fundamental

Given the `definitions` of an OpenAPI spec, will return a hash-ref
mapping names of definitions considered non-fundamental to a
value. The value is either the name of another definition that _is_
fundamental, or or `undef` if it just contains e.g. a string. It will
instead be a reference to such a value if it is to an array of such.

This may be used e.g. to determine the "real" input or output of an
OpenAPI operation.

Non-fundamental is determined according to these heuristics:

- object definitions that only have one property (which the author calls
"thin objects"), or that have two properties, one of whose names has
the substring "count" (case-insensitive).
- object definitions that have all the same properties as another, and
are not the shortest-named one between the two.
- object definitions whose properties are a strict subset of another.

# OPENAPI SPEC EXTENSIONS

## `x-id-field`

Under `/definitions/$defname`, a key of `x-id-field` will name a
field within the `properties` to be the unique ID for that entity.
If it is not given, the `id` field will be used if in the spec, or
created if not.

This will form the ostensible "key" for the generated table. If the
key used here is an integer type, it will also be the primary key,
being a suitable "natural" key. If not, then a "surrogate" key (with a
generated name starting with `_relational_id`) will be added as the primary
key. If a surrogate key is made, the natural key will be given a unique
constraint and index, making it still suitable for lookups. Foreign key
relations will however be constructed using the relational primary key,
be that surrogate if created, or natural.

## `x-view-of`

Under `/definitions/$defname`, a key of `x-view-of` will name another
definition (NB: not a full JSON pointer). That will make `$defname`
not be created as a table. The handling of creating the "view" of the
relevant table is left to the CRUD implementation. This gives it scope
to use things like the current requesting user, or web parameters,
which otherwise would require a parameterised view. These are not widely
available.

## `x-artifact`

Under `/definitions/$defname/properties/$propname`, a key of
`x-artifact` with a true value will indicate this is not to be stored,
and will not cause a column to be created. The value will instead be
derived by other means. The value of this key may become the definition
of that derivation.

## `x-input-only`

Under `/definitions/$defname/properties/$propname`, a key of
`x-input-only` with a true value will indicate this is not to be stored,
and will not cause a column to be created. This may end up being merged
with `x-artifact`.

# DEBUGGING

To debug, set environment variable `SQLTP_OPENAPI_DEBUG` to a true value.

# AUTHOR

Ed J, `<etj at cpan.org>`

# LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[SQL::Translator](https://metacpan.org/pod/SQL%3A%3ATranslator).

[SQL::Translator::Parser](https://metacpan.org/pod/SQL%3A%3ATranslator%3A%3AParser).

[JSON::Validator::OpenAPI::Mojolicious](https://metacpan.org/pod/JSON%3A%3AValidator%3A%3AOpenAPI%3A%3AMojolicious).
