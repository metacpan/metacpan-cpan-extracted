# NAME

Prancer::Plugin::Database

# SYNOPSIS

This plugin enables connections to a database and exports a keyword to access
those configured connections.

It's important to remember that when running your application in a single-
threaded, single-process application server like, say, [Twiggy](https://metacpan.org/pod/Twiggy), all users of
your application will use the same database connection. If you are using
callbacks then this becomes very important and you will want to take care to
avoid crossing transactions or expecting a database connection or transaction
to be in the same state it was before a callback.

To use a database connector, add something like this to your configuration
file:

    database:
        connection-name:
            driver: Prancer::Plugin::Database::Driver::DriverName
            options:
                username: test
                password: test
                database: test
                hostname: localhost
                port: 5432
                autocommit: true
                charset: utf8
                connection_check_threshold: 10
                dsn_extra:
                    RaiseError: 0
                    PrintError: 1
                on_connect:
                    - SET search_path=public

The "connection-name" can be anything you want it to be. This will be used when
requesting a connection from the plugin to determine which connection to return.
If only one connection is configured it may be prudent to call it "default" as
that is the name that Prancer will look for if no connection name is given.
For example:

    use Prancer::Plugin::Database qw(database);

    Prancer::Plugin::Database->load();

    my $dbh = database;  # returns whatever connection is called "default"
    my $dbh = database("foo");  # returns the connection called "foo"

# OPTIONS

- database

    **REQUIRED** The name of the database to connect to.

- username

    The username to use when connecting. If this option is not set then the default
    is the user running the application server or the current user.

- password

    The password to use when connecting. If this option is not set then the default
    is to connect with no password.

- hostname

    The host name of the database server. If this option is not set then the
    default is to connect to localhost.

- port

    The port number on which the database server is listening. If this option is
    not set then the default is to connect on the database's default port.

- autocommit

    If set to a true value -- like 1, yes, or true -- then this will enable
    autocommit. If set to a false value -- like 0, no, or false -- then this will
    disable autocommit. By default, autocommit is enabled.

- charset

    The character set to connect to the database with. If this is set to "utf8"
    then the database connection will attempt to make UTF8 data Just Work if
    available.

- connection\_check\_threshold

    This sets the number of seconds that must elapse between calls to get a
    database handle before performing a check to ensure that a database connection
    still exists and will reconnect if one does not. This handles cases where the
    database handle hasn't been used in a while and the underlying connection has
    gone away. If this is not set then it will default to 30 seconds.

- dsn\_extra

    If you have any further connection parameters that need to be appended to the
    dsn then you can put them in the configuration as a hash. This hash will be
    merged into the default parameters and overwrite any that are duplicated. The
    dsn parameters set by default are `AutoCommit` to 1, `RaiseError` to 1, and
    `PrintError` to 0. This option will take precedence over the `autocommit`
    flag above.

- on\_connect

    This can be an array of commands execute on a successful connection. These will
    be executed on every connection so if the connection goes away but is re-
    established then these commands will be run again.

# CREDIT

This module is derived from [Dancer::Plugin::Database](https://metacpan.org/pod/Dancer::Plugin::Database). Thank you to David
Precious.

# COPYRIGHT

Copyright 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# SEE ALSO

- [Prancer](https://metacpan.org/pod/Prancer)
