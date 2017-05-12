[![Build Status](https://travis-ci.org/karupanerura/SQL-Translator-Producer-GoogleBigQuery.svg?branch=master)](https://travis-ci.org/karupanerura/SQL-Translator-Producer-GoogleBigQuery) [![Coverage Status](http://codecov.io/github/karupanerura/SQL-Translator-Producer-GoogleBigQuery/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/SQL-Translator-Producer-GoogleBigQuery?branch=master)
# NAME

SQL::Translator::Producer::GoogleBigQuery - Google BigQuery specific producer for SQL::Translator

# SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::GoogleBigQuery;

    my $t = SQL::Translator->new( parser => '...' );
    $t->producer('GoogleBigQuery', outdir => './'); ## dump to ...
    $t->translate;

# DESCRIPTION

This module will produce text output of the schema suitable for Google BigQuery.
It will be a '.json' file of BigQuery schema format.

# ARGUMENTS

- `outdir`

    Base directory of output schema files.

- `typemap`

    Override type mapping from DBI type to Goolge BigQuery type.

    Example:

        use DBI qw/:sql_types/;
        use SQL::Translator;
        use SQL::Translator::Producer::GoogleBigQuery;

        my $t = SQL::Translator->new( parser => '...' );
        $t->producer('GoogleBigQuery', outdir => './', typemap => { SQL_TINYINT() => 'boolean' });
        $t->translate;

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
