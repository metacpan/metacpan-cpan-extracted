# NAME

Starch::Store::DBI - Starch storage backend using DBI.

# SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::DBI',
            dbh => [
                $dsn,
                $username,
                $password,
                { RaiseError => 1 },
            ],
            table => 'my_states',
        },
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [DBI](https://metacpan.org/pod/DBI) to set and get state data.

Consider using [Starch::Store::DBIx::Connector](https://metacpan.org/pod/Starch::Store::DBIx::Connector) instead
of this store as [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) provides superior re-connection
and transaction handling capabilities.

The table in your database should contain three columns.  This
is the SQLite syntax for creating a compatible table which you
can modify to work for your particular database's syntax:

    CREATE TABLE starch_states (
        key TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        expiration INTEGER NOT NULL
    )

# REQUIRED ARGUMENTS

## dbh

This must be set to either array ref arguments for ["connect" in DBI](https://metacpan.org/pod/DBI#connect)
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
[method proxy](https://metacpan.org/pod/Starch#METHOD-PROXIES)
is a good way to link your existing [DBI](https://metacpan.org/pod/DBI) object constructor
in with Starch so that starch doesn't build its own.

# OPTIONAL ARGUMENTS

## serializer

A [Data::Serializer::Raw](https://metacpan.org/pod/Data::Serializer::Raw) for serializing the state data for storage
in the ["data\_column"](#data_column).  Can be specified as string containing the
serializer name, a hash ref of Data::Serializer::Raw arguments, or as a
pre-created Data::Serializer::Raw object.  Defaults to `JSON`.

Consider using the `JSON::XS` or `Sereal` serializers for speed.

`Sereal` will likely be the fastest and produce the most compact data.

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
Starch-Store-DBI GitHub issue tracker:

[https://github.com/bluefeet/Starch-Store-DBI/issues](https://github.com/bluefeet/Starch-Store-DBI/issues)

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
