# NAME

Starch::Store::DBIx::Connector - Starch storage backend using DBIx::Connector.

# SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::DBIx::Connector',
            connector => [
                $dsn,
                $username,
                $password,
                { RaiseError=>1, AutoCommit=>1 },
            ],
        },
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) to set and get state data.

The table in your database should contain three columns.  This
is the SQLite syntax for creating a compatible table which you
can modify to work for your particular database's syntax:

    CREATE TABLE starch_states (
        key TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        expiration INTEGER NOT NULL
    )

# REQUIRED ARGUMENTS

## connector

This must be set to either an array ref arguments for [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector)
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
[method proxy](https://metacpan.org/pod/Starch#METHOD-PROXIES)
is a good way to link your existing [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) object
constructor in with Starch so that starch doesn't build its own.

# OPTIONAL ARGUMENTS

## serializer

A [Data::Serializer::Raw](https://metacpan.org/pod/Data::Serializer::Raw) for serializing the state data for storage
in the ["data\_column"](#data_column).  Can be specified as string containing the
serializer name, a hash ref of Data::Serializer::Raw arguments, or as a
pre-created Data::Serializer::Raw object.  Defaults to `JSON`.

Consider using the `JSON` or `Sereal` serializers for speed.

`Sereal` will likely be the fastest and produce the most compact data.

## method

The [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) method to call when executing queries.
Must be one of `run`, `txn`, or `svp`.  Defaults to `run`.

## mode

The [connection mode](https://metacpan.org/pod/DBIx::Connector#Connection-Modes) to use
when running the ["method"](#method).  Defaults to `undef` which lets
[DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) use whichever mode it has been configured to use.
Must be on of `ping`, `fixup`, `no_ping`, or `undef`.

Typically you will not want to set this as you will have provided
a pre-built [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) object, using a method proxy, which
you've already called ["mode" in DBIx::Connector](https://metacpan.org/pod/DBIx::Connector#mode) on.

## table

The table name where states are stored in the database.
Defaults to `starch_states`.

## key\_column

The column in the ["table"](#table) where the state ID is stored.
Defaults to `key`.

## data\_column

The column in the ["table"](#table) which will hold the state
data.  Defaults to `data`.

## expiration\_column

The column in the ["table"](#table) which will hold the epoch time
when the state should be expired.  Defaults to `expiration`.

# ATTRIBUTES

## insert\_sql

The SQL used to create state data.

## update\_sql

The SQL used to update state data.

## exists\_sql

The SQL used to confirm whether state data already exists.

## select\_sql

The SQL used to retrieve state data.

## delete\_sql

The SQL used to delete state data.

# METHODS

## set

Set ["set" in Starch::Store](https://metacpan.org/pod/Starch::Store#set).

## get

Set ["get" in Starch::Store](https://metacpan.org/pod/Starch::Store#get).

## remove

Set ["remove" in Starch::Store](https://metacpan.org/pod/Starch::Store#remove).

# SUPPORT

Please submit bugs and feature requests to the
Starch-Store-DBIx-Connector GitHub issue tracker:

[https://github.com/bluefeet/Starch-Store-DBIx-Connector/issues](https://github.com/bluefeet/Starch-Store-DBIx-Connector/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
