package Prancer::Session::Store::Database;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.01';

1;

=head1 NAME

Prancer::Session::Store::Database

=head1 SYNOPSIS

This module implements a session handler that stores sessions in a database. It
creates its own database connection, separate from any existing database
connection, to avoid any issues with transactions. It wraps all changes to the
database in transactions to ensure consistency.

This configuration expects a database table that looks like this:

    CREATE TABLE session (
        id CHAR(72) NOT NULL,
        application VARCHAR DEFALUT '' NOT NULL,
        timeout integer DEFAULT date_part('epoch'::text, now()) NOT NULL,
        data TEXT
    );

    CREATE UNIQUE INDEX session_uq ON sessions (id, application);
    CREATE INDEX session_timeout_ix ON sessions (timeout);

Additional columns may be added as desired but they will not be used by this
session handler.

To use this session handler, add this to your configuration file:

    session:
        store:
            driver: Prancer::Session::Store::Database::Driver::DriverName
            options:
                table: sessions
                database: test
                username: test
                password: test
                hostname: localhost
                port: 5432
                charset: utf8
                connection_check_threshold: 10
                dsn_extra:
                    RaiseError: 0
                    PrintError: 1
                on_connect:
                    - SET search_path=public
                expiration_timeout: 3600
                autopurge: 0
                autopurge_probability: 0.1
                application: foobar

=head1 OPTIONS

=over

=item table

The name of the table in your database to use to store sessions. This name may
include a schema name, like C<public.sessions>. Otherwise the default schema of
the database user will be used. If this option is not provided then the default
table name is C<sessions>.

=item database

B<REQUIRED> The name of the database to connect to. If using SQLite, this
should be the path to the database file.

=item username

The username to use when connecting. If this option is not set the default is
the user running the application server. If using SQLite then this will be
ignored.

=item password

The password to use when connecting. If this option is not set the default is
to connect with no password. If using SQLite then this will be ignored.

=item hostname

The host name of the database server. If this option is not set the default is
to connect to localhost. If using SQLite then this will be ignored.

=item port

The port number on which the database server is listening. If this option is
not set the default is to connect on the database's default port. If using
SQLite then this will be ignored.

=item charset

The character set to connect to the database with. If this is set to "utf8"
then the database connection will attempt to make UTF8 data Just Work if
available.

=item connection_check_threshold

This sets the number of seconds that must elapse between calls to get a
database handle before performing a check to ensure that a live database
connection still exists. If the check for a live database connection fails then
the session handler will attempt to reconnect. This handles cases where the
database handle hasn't been used in a while and the underlying connection has
gone away. If this is not set it will default to 30 seconds.

=item dsn_extra

If you have any further connection parameters that need to be appended to the
dsn then you can put them in the configuration as a hash. This hash will be
merged into the default parameters and overwrite any that are duplicated. The
dsn parameters set by default are C<AutoCommit> to 0, C<RaiseError> to 1, and
C<PrintError> to 0.

=item on_connect

This can be an array of commands execute on a successful connection. These will
be executed on every connection so if the connection goes away but is re-
established then these commands will be run again.

=item timeout

Tthis is the number of seconds a session should last in the database before it
will be automatically purged. The default is to purge sessions after 1800
seconds (30 minutes).

=item autopurge

This flag controls whether sessions will be automatically purged by Prancer.
If set to 1, the default, then on 10% of requests to your application, Prancer
will delete from the database any session that has timed out. If set to 0 then
sessions will never be removed from the database. Note that this doesn't
control whether sessions time out, only whether they get removed from the
database.

=item autopurge_probability

This is the probability that autopurge will run on any given request. By
default, this value is 0.1, or 10%, meaning that 1 in every 10 requests will
attempt to purge expired sessions. This can be set to "1" to purge on every
session action or to something extremely small like 0.001 to purge very, very
infrequently. Or you can export purging duties to another program entirely.

=item application

If multiple applications will be using the same session table then this option
may be used to distinguish between them. This key will be used in the
C<application> column of the sessions table.

=back

=head1 COPYRIGHT

Copyright 2014 Paul Lockaby. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Prancer>

=item

L<Prancer::Session>

=back

=cut
