# NAME

Test::DBIC::Pg - Connect to and deploy a DBIx::Class::Schema on Postgres

# SYNOPSIS

The preferred way:
```perl
#! perl -w
use Test::More;
use Test::DBIC::Pg;

my $td = Test::DBIC::Pg->new(schema_class => 'My::Schema');
my $schema = $td->connect_dbi_ok();
...
$schema->storage->disconnect();
$td->drop_dbic_ok();
done_testing();
```
The compatible with [Test::DBIC::SQLite](https://metacpan.org/pod/Test%3A%3ADBIC%3A%3ASQLite) way:
```perl
#! perl -w
use Test::More;
use Test::DBIC::Pg;
my $schema = connect_dbic_pg_ok('My::Schema');
...
$schema->storage->disconnect();
drop_dbic_pg_ok();
done_testing();
```

# DESCRIPTION

This is an implementation of `Test::DBIC::Pg` that uses the [Moo::Role](https://metacpan.org/pod/Moo%3A%3ARole):
[Test::DBIC::DBDConnector](https://metacpan.org/pod/Test%3A%3ADBIC%3A%3ADBDConnector) from the [Test::DBIC::SQLite](https://metacpan.org/pod/Test%3A%3ADBIC%3A%3ASQLite) package.

It will `import()` [warnings](https://metacpan.org/pod/warnings) and [strict](https://metacpan.org/pod/strict) for you.

## `Test::DBIC::Pg->new`

    my $td = Test::DBIC::Pg->new(%parameters);
    my $schema = $td->connect_dbic_ok();
    ...
    $schema->storage->disconnect();
    $td->drop_dbic_ok();

### Parameters

Named, list:

- **`schema_class`** => `$schema_class` (_Required_)  
    The class name of the [DBIx::Class::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema) to use.

- **`dbi_connect_info`** => `$pg_connect_info` (_Optional_,
`{ dsn => "dbi:Pg:dbname=_test_dbic_pg_$$" }`)  
    This is a HashRef that will be used to connect to the PostgreSQL server:

    - **`dsn`** => `dbi:Pg:host=mypg;dbname=_my_test_x`  
        This Data Source Name (dsn) must also contain the `dbi:Pg:` bit that is needed
        for [DBI](https://metacpan.org/pod/DBI) to connect to your database/server.
        We do allow for DBI options syntax: `dbi:Pg(FetchHashKeyName=>NAME_uc):dbname=blah`

        If your database doesn't exist it will be created. This will need an extra
        temporary database connection.

    - **`username`** => `$username`  
        This is the username that will be used to connect to the PostgreSQL server, if
        omitted [DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg) will try to use `$ENV{PGUSER}`.

    - **`password`** => `$password`  
        This is the password that will be used to connect to the PostgreSQL
        server, if omitted [DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg) will
        look at `~/.pgpass` to see if it can find a suitable password in there.
        (See also postgres docs for `$ENV{PGPASSWORD}` en `$ENV{PGPASSFILE}`).

    - **`options`** => `$options_hash`  
        This options hashref is also passed to the
        `DBIx::Class::Schema->connect()` method for extra options. This hash
        will contain the extra key/value pair `skip_version => 1` whenever the
        **wants\_deploy** attribute is true.

- **`pre_deploy_hook`** => `$pre_deploy_hook` (_Optional_)  
    A CodeRef to execute _before_ `$schema->deploy` is called.

    This CodeRef is called with an instantiated `$your_schema_class` object as argument.

- **`post_connect_hook`** => `$post_connect_hook` (_Optional_)  
    A coderef to execute _after_ `$schema->deploy` is called, if at all.

    This coderef is called with an instantiated `$your_schema_class` object as argument.

- **`TMPL_DB`** => `$template_database` (_Optional_, `template1`)  
    In order to create and drop your test database a temporary connection needs to
    be made to the PostgreSQL instance from your dsn, but with a template database
    (tools like `createdb` and `dropdb` also do this in the background).
    The default database for these type of connections is `template1` - and this
    module uses that as well - but your DBA could have configured a different
    database for this function, therefore we support the setting of `TMPL_DB`.

## `$td->connect_dbic_ok()`

This method is inherited from [Test::DBIC::DBDConnoctor](https://metacpan.org/pod/Test%3A%3ADBIC%3A%3ADBDConnoctor).

If the database needs deploying, there will be another temporary database
connection to the template database in order to issue the `CREATE DATABASE
$dbname` statement.

### Returns

An initialised instance of `$schema_class`.

## `$td->drop_dbic_ok`

This method implements a `dropdb $dbname`, in order not to litter your
server with test databases.

During this method there will be another temporary database connection to the
template database, in order to issue the `DROP DATABASE $dbname` statement
(that cannot be run from the connection with the test database it self).

## `connect_dbic_pg_ok(@parameters)`

Create a PostgreSQL database and deploy a dbic\_schema. This function is provided
for compatibility with [Test::DBIC::SQLite](https://metacpan.org/pod/Test%3A%3ADBIC%3A%3ASQLite).

See [Test::DBIC::Pg->new](#test-dbic-pg-new) for further information,
although only these 4 arguments are supported.

### Parameters

Positional:

1. `$schema_class` (Required)
2. `$pg_connect_info` (Optional)
3. `$pre_deploy_hook` (Optional)
4. `$post_connect_hook` (Optional)

## `drop_dbic_pg_ok()`

This function uses the cached information of the call to `connect_dbic_pg_ok()`
and clears it after the database is dropped, using another temporary connection
to the template database.

See [the `drop_dbic_ok()` method](#td-drop_dbic_ok).

## Implementation of `MyDBD_connection_parameters`

As there is no fiddling with the already provided connection paramaters, this
method sets up the connection parameter for the temporary connection to the
template database in order to create or drop the (temporary) test database.

## Implementation of `MyDBD_check_wants_deploy`

In this method the temporary connection to the template database is set up and a
list of available database is requested - via `$dbh->data_sources()` - to
check if the test database already exists. If it doesn't, the database will be
created and a true value is returned, otherwise a false value is returned and no
new database is created.

# AUTHOR

© MMXXI - Abe Timmerman <abeltje@cpan.org>

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
