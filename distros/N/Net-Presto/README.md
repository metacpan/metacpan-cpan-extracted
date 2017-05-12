# NAME

Net::Presto - Presto client library for Perl

# SYNOPSIS

    use Net::Presto;

    my $presto = Net::Presto->new(
        server    => 'localhost:8080',
        catalog   => 'hive',
        schema    => 'mydb',
        user      => 'scott',
        source    => 'myscript',   # defaults to Net::Presto/$VERSION
        time_zone => 'US/Pacific', # optional
        language  => 'English',    # optional
    );

    # easy to use interfaces
    my $rows = $presto->select_all('SELECT * FROM ...');
    my $row = $presto->select_row('SELECT * FROM ... LIMIT 1');
    my $col = $presto->select_one('SELECT COUNT(1) FROM ...');

    $presto->do('CREATE TABLE ...');

    # See Net::Presto::Statament for more details of low level interfaces
    my $sth = $presto->execute('SELECT * FROM ...');
    while (my $rows = $sth->fetch_hashref) {
        for my $row (@$rows) {
            $row->{column_name};
        }
    }

# DESCRIPTION

Presto is a distributed SQL query engine for big data.

[https://prestodb.io/](https://prestodb.io/)

Net::Presto is a client library for Perl to run queries on Presto.

# CONSTRUCTOR

## `Net::Presto->new(%options) :Net::Presto`

Creates and return a new Net::Presto instance with options.

_%options_ might be:

- server

    address\[:port\] to a Presto coordinator

- catalog

    Catalog (connector) name of Presto such as \`hive-cdh4\`, \`hive-hadoop1\`, etc.

- schema

    Default schema name of Presto. You can read other schemas by qualified name like \`FROM myschema.table1\`.

- user

    User name to connect to a Presto

- source

    Source name to connect to a Presto. This name is shown on Presto web interface.

- time\_zone

    Time zone of the query. Time zone affects some functions such as \`format\_datetime\`.

- language

    Language of the query. Language affects some functions such as \`format\_datetime\`.

- properties

    Session properties.

# METHODS

## `$presto->select_all($query) :ArrayRef[HashRef[Str]]`

Shortcut for execute and fetchrow\_hashref

## `$presto->select_row($query) :HashRef[Str]`

Shortcut for execute and fetchrow\_hashref->\[0\]

## `$presto->select_one($query) :Str`

Shortcut for execute and fetch->\[0\]

## `$presto->do($query) :Int`

Execute a single statement.

## `$presto->execute($query) :Net::Presto::Statement`

Execute a statement and returns a [Net::Presto::Statement](https://metacpan.org/pod/Net::Presto::Statement) object.

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>
