# NAME

SQL::Validator - Validate JSON-SQL Schemas

# ABSTRACT

Validate JSON-SQL Schemas

# SYNOPSIS

    use SQL::Validator;

    my $sql = SQL::Validator->new;

    # my $valid = $sql->validate({
    #   insert => {
    #     into => {
    #       table => 'users'
    #     },
    #     default => true
    #   }
    # });

    # i.e. INSERT INTO users DEFAULT VALUES;

    # $sql->error->report('insert')

# DESCRIPTION

This package provides a
[json-sql](https://github.com/iamalnewkirk/json-sql#readme) data structure
validation library based around [json-schema](https://json-schema.org).

# ATTRIBUTES

This package has the following attributes:

## schema

    schema(Any)

This attribute is read-only, accepts `(Any)` values, and is optional.

## validator

    validator(InstanceOf["JSON::Validator"])

This attribute is read-only, accepts `(InstanceOf["JSON::Validator"])` values, and is optional.

## version

    version(Str)

This attribute is read-only, accepts `(Str)` values, and is optional.

# METHODS

This package implements the following methods:

## error

    error() : InstanceOf["SQL::Validator::Error"]

The error method validates the JSON-SQL schema provided.

- error example #1

        # given: synopsis

        $sql->validate({});

        my $error = $sql->error;

- error example #2

        # given: synopsis

        $sql->validate({select => {}});

        my $error = $sql->error;

## validate

    validate(HashRef $schema) : Bool

The validate method validates the JSON-SQL schema provided.

- validate example #1

        # given: synopsis

        my $valid = $sql->validate({
          insert => {
            into => {
              table => 'users'
            },
            default => 'true'
          }
        });

        # VALID

- validate example #2

        # given: synopsis

        my $valid = $sql->validate({
          insert => {
            table => 'users',
            default => 'true'
          }
        });

        # INVALID

- validate example #3

        # given: synopsis

        my $valid = $sql->validate({
          insert => {
            into => 'users',
            values => [1, 2, 3]
          }
        });

        # INVALID

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/sql-validator/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/sql-validator/wiki)

[Project](https://github.com/iamalnewkirk/sql-validator)

[Initiatives](https://github.com/iamalnewkirk/sql-validator/projects)

[Milestones](https://github.com/iamalnewkirk/sql-validator/milestones)

[Contributing](https://github.com/iamalnewkirk/sql-validator/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/sql-validator/issues)
