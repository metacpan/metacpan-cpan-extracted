[![Build Status](https://travis-ci.org/karupanerura/SQL-Translator-Producer-DBIxSchemaDSL.svg?branch=master)](https://travis-ci.org/karupanerura/SQL-Translator-Producer-DBIxSchemaDSL)
# NAME

SQL::Translator::Producer::DBIxSchemaDSL - DBIX::Schema::DSL specific producer for SQL::Translator

# SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::DBIxSchemaDSL;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('DBIxSchemaDSL');
    $t->translate;

# DESCRIPTION

This module will produce text output of the schema suitable for DBIx::Schema::DSL.

# ARGUMENTS

- `default_not_null`

    Enables `default_not_null` in DSL.

- `default_unsigned`

    Enables `default_unsigned` in DSL.

- `typemap`

    Override type mapping from DBI type to DBIx::Schema::DSL type.

    Example:

        use DBI qw/:sql_types/;
        use SQL::Translator;
        use SQL::Translator::Producer::DBIx::Schema::DSL;

        my $t = SQL::Translator->new( parser => '...' );
        $t->producer('GoogleBigQuery', { typemap => { SQL_TINYINT() => 'integer' } });
        $t->translate;

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
