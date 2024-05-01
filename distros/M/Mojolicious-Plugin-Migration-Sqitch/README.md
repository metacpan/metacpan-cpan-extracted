# NAME

Mojolicious::Plugin::Migration::Sqitch - Run Sqitch database migrations from a Mojo app

# SYNOPSIS

    # Register plugin
    $self->plugin('Migration::Sqitch' => {
      dsn       => 'dbi:mysql:host=localhost;port=3306;database=myapp',
      registry  => 'sqitch_myapp',
      username  => 'sqitch',
      password  => 'world-banana-tuesday',
      directory => '/schema',
    });

    # use from command-line (normally done by startup script to ensure db up to date before app starts)
    tyrrminal@prodserver:/app$ script/myapp schema-initdb
    [2024-04-30 11:26:47.91166] [8982] [info] Database initialized

    tyrrminal@prodserver:/app$ script/myapp schema-migrate
    Deploying changes to db:MariaDB://sqitch@db/myapp_dev
      + initial_schema .. ok
    [2024-04-30 11:29:13.80192] [8985] [info] Database migration complete

    # Revert a migration in dev
    tyrrminal@devserver:/app$ script/myapp schema-migrate schema-migrate revert
    Revert all changes from db:MariaDB://sqitch@db/myapp_dev? [Yes] 
      - initial_schema .. ok
    [2024-04-30 11:26:47.91166] [8982] [info] Database migration complete

    # Start over from scratch
    tyrrminal@devserver:/app$ script/myapp schema-initdb --reset
    This will result in all data being deleted from the database. Are you sure you want to continue? [yN] y
    [2024-04-30 11:28:10.73379] [8983] [info] Database reset
    [2024-04-30 11:28:10.73501] [8983] [info] Database initialized

# DESCRIPTION

Mojolicious::Plugin::Migration::Sqitch enables the use of sqitch via Mojolicious
commands. The primary advantage of this is single-point configuration: just pass
the appropriate parameters in at plugin registration and then you don't have to
worry about passwords, DSNs, and filesystem locations for running sqitch commands
thereafter.

This plugin also provides some additional functionality for initializing the 
database, which can't easily be done strictly through sqitch migrations without
hardcoding database names, which can be troublesome depending on the deployment.

# METHODS

[Mojolicious::Plugin::Migration::Sqitch](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AMigration%3A%3ASqitch) inherits all methods from 
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones

## register( $args )

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. The following keys are required
in `$args`

#### dsn

The [data source name](https://en.wikipedia.org/wiki/Data_source_name) for 
connecting to the _application_ database.

E.g., `dbi:mysql:host=db;port=3306;database=myapp_prod`

#### registry

The name of the database used by sqitch for tracking migrations

E.g., `myapp_prod_sqitch`

#### username

Database username for sqitch migrations. As this account needs to run arbitrary
SQL code (both DDL and DML), it must have sufficiently high privileges. This
can be the same account used by the application, if this consideration is taken
into account.

#### password

The password corresponding to the sqitch migration database account

#### directory

The on-disk location of the sqitch migrations directory. Sqitch expects to find
`deploy`, `revert`, and `verify` subdirectories there, as well as the 
`sqitch.plan` file. It must also contain a `sqitch.conf` file, but the only
contents of this file needed are:

    [core]
      engine = $ENGINE

With `$ENGINE` replaced by the actual engine name, e.g., `mysql` or `pgsql`.
This plugin handles the rest of the configuration that would normally be found
in that file.

E.g., `/schema` (in a containerized environment), or `/home/mojo/myapp/schema`

## run\_schema\_initialization( \\%args )

Create the configured application and migration databases, if either or both
do not already exist. One key is regarded in the `args` HashRef:

#### reset

If this key is given and is assigned a "truthy" value, the application and 
migration databases will be dropped (if either or both exists) before being 
re-created. _This is a destructive operation!_

## run\_schema\_migration( $sqitch\_subcommand )

Run the specified `$sqitch_subcommand` including any additional parameters 
(e.g., `deploy` or `revert -to @HEAD^1`). Returns the exit status of the 
sqitch command to indicate success (zero) or failure (non-zero).

# COMMANDS

## schema-initdb \[--reset\]

Mojolicious command to execute ["run\_schema\_initialization"](#run_schema_initialization)

If the `--reset` flag is given, corresponding to the methods's ["reset"](#reset) arg 
key, a console warning is given alerting the user of the destructive nature of 
this operation and must be manually approved before continuing.

## schema-migrate \[args\]

Mojolicious command to execute ["run\_schema\_migration"](#run_schema_migration). Any additional args
given are whitespace-joined and passed on to that method. If no args are 
provided, `deploy` is assumed.

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
