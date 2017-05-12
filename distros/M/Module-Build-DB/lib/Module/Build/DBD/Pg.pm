package Module::Build::DBD::Pg;

use strict;
use warnings;
our $VERSION = '0.10';

sub get_client { 'psql' }

sub get_db_and_command {
    my ($class, $client, $p) = @_;

    my $user = $p->{db_super_user} || $p->{username} || $p->{user};
    my @cmd = (
        $client,
        ($user ? ( '--username' => $user ) : ()),
        '--quiet',
        '--no-psqlrc',
        '--no-align',
        '--tuples-only',
        '--set' => 'ON_ERROR_ROLLBACK=1',
        '--set' => 'ON_ERROR_STOP=1',
    );
    push @cmd, '--host' => $p->{host} if $p->{host};
    push @cmd, '--port' => $p->{port} if $p->{port};

    # Hopefully this is sufficiently OS-independant for us to get away with it.
    unshift @cmd, $^X, '-e', '$ENV{PGPASSWORD} = shift; exec @ARGV', $p->{db_super_pass}
        if $p->{db_super_pass};

    return $p->{dbname}, \@cmd;
}

sub get_db_option {
    my ($class, $db) = @_;
    return ('--dbname' => $db);
}

sub get_create_db_command {
    my ($class, $cmd, $db) = @_;
    $class->get_execute_command( $cmd, 'template1', qq{CREATE DATABASE "$db"});
}

sub get_drop_db_command {
    my ($class, $cmd, $db) = @_;
    $class->get_execute_command( $cmd, 'template1', qq{DROP DATABASE IF EXISTS "$db"});
}

sub get_check_db_command {
    my ($class, $cmd, $db) = @_;
    $class->get_execute_command( $cmd, 'template1', qq{
        SELECT 1
          FROM pg_catalog.pg_database
         WHERE datname = '$db';
    });
}

sub get_execute_command {
    my ($class, $cmd, $db, $sql) = @_;
    return (
        @$cmd,
        $class->get_db_option($db),
        '--command' => $sql,
    );
}

sub get_file_command {
    my ($class, $cmd, $db, $fn) = @_;
    return (
        @$cmd,
        $class->get_db_option($db),
        '--file' => $fn,
    );
}

sub get_meta_table_sql {
    my ($class, $table) = @_;
    return qq{
        SET client_min_messages=warning;
        CREATE TABLE $table (
            label TEXT PRIMARY KEY,
            value INT  NOT NULL DEFAULT 0,
            note  TEXT NOT NULL
        );
        RESET client_min_messages;
    }
}

1;

=head1 Name

Module::Build::DBD:Pg - PostgreSQL specifics for Module::Build::DB

=head1 Description

This module contains a number of class methods called by L<Module::Build::DB>
to handle PostgreSQL specific tasks when detecting, building, and updating a
database.

=head2 Methods

All methods are class methods.

=head3 C<get_client()>

  my $client = Module::Build::DBD::Pg->get_client;

Returns the name of the client to use to connect to PostgreSQL. For now,
that's just C<psql>, which is fine if it's in your path. Some code to search
for a client might be added in the future. Either way, it's best to specify
use the C<--db_client> option to avoid all ambiguity.

=head3 C<get_db_and_command()>

  my ($db_name, $cmd) = Module::Build::DBD::Pg->get_db_and_command($client, $params);

Returns a database name culled from C<$params> and an array reference with
C<$client> and all required options for all access to the database. C<$params>
contains both the contents of the context configuration file's DBI section and
the attributes defined in the driver DSN (e.g., C<dbname=foo> in
C<dbi:Pg:dbname=foo>).

=head3 C<get_db_option()>

  my @opts = Module::Build::DBD::Pg->get_db_option($db_name);

Returns a list of options to be appended to the command returned by
C<get_db_and_command()> to connect to a specific database. For PostgreSQL,
that's simply C<< ('--dbname' => $dbname) >>.

=head3 C<get_create_db_command()>

  my @command = Module::Build::DBD::Pg->get_create_db_command($cmd, $db);

Returns a command list suitable for passing to C<system()> that will create a
new database. C<$cmd> is the command returned by C<get_db_and_command()> and
C<$db> is the name of the database to be created.

=head3 C<get_drop_db_command()>

  my @command = Module::Build::DBD::Pg->get_drop_db_command($cmd, $db);

Returns a command list suitable for passing to C<system()> that will drop an
existing database. C<$cmd> is the command returned by C<get_db_and_command()>
and C<$db> is the name of the database to be dropped.

=head3 C<get_check_db_command()>

  my @command = Module::Build::DBD::Pg->get_check_db_command($cmd, $db);

Returns a command list suitable for passing to C<system()> that will, when
executed, output a 1 when C<$db> exists and nothing when C<$db> does not
exist. C<$cmd> is the command returned by C<get_db_and_command()> and C<$db>
is the name of the database to be checked.

=head3 C<get_execute_command()>

  my @command = Module::Build::DBD::Pg->get_execute_command($cmd, $db, $sql);

Returns a command list suitable for passing to C<system()> that will execute
the SQL in C<$sql> and return its output, if any. C<$cmd> is the command
returned by C<get_db_and_command()>, C<$db> is the name of the database to be
connect to for the query, and C<$sql> is the SQL command or commands to be
executed.

=head3 C<get_file_command()>

  my @command = Module::Build::DBD::Pg->get_file_command($cmd, $db, $sql);

Returns a command list suitable for passing to C<system()> that will execute
the SQL in C<$file> and return its output, if any. C<$cmd> is the command
returned by C<get_db_and_command()>, C<$db> is the name of the database to be
connect to for the query, and C<$file> is a file with SQL commands.

=head3 C<get_meta_table_sql()>

  my $sql = Module::Build::DBD::Pg->get_meta_table_sql;

Returns an SQL string that creates a metadata table named C<$table_name>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright

Copyright (c) 2008-2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut
