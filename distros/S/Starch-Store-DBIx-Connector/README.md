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
            table => 'my_states',
        },
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) to set and get state data.

Very little is documented in this module as it is just a subclass
of [Starch::Store::DBI](https://metacpan.org/pod/Starch::Store::DBI) modified to use [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector)
instead of [DBI](https://metacpan.org/pod/DBI).

# REQUIRED ARGUMENTS

## connector

This must be set to either an array ref arguments for [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector)
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
[method proxy](https://metacpan.org/pod/Starch#METHOD-PROXIES)
is a good way to link your existing [DBIx::Connector](https://metacpan.org/pod/DBIx::Connector) object
constructor in with Starch so that starch doesn't build its own.

# OPTIONAL ARGUMENTS

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
