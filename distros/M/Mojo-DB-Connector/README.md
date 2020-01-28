# NAME

[Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) - Create and cache DB connections using common connection info

# STATUS

<div>
    <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use Mojo::DB::Connector;

    # use default connection info or use connection info
    # set in environment variables
    my $connector  = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection;
    my $results    = $connection->db->query(...);

    # pass connection info in (some defaults still used)
    my $connector  = Mojo::DB::Connector->new(host => 'batman.com', userinfo => 'sri:s3cret');
    my $connection = $connector->new_connection(database => 'my_s3cret_database');
    my $results    = $connection->db->query(...);

    # cache connections using Mojo::DB::Connector::Role::Cache
    my $connector = Mojo::DB::Connector->new->with_roles('+Cache');

    # fresh connection the first time
    my $connection = $connector->cached_connection(database => 'my_database');

    # later somewhere else...
    # same connection (Mojo::mysql or Mojo::Pg object) as before
    my $connection = $connector->cached_connection(database => 'my_database');

# DESCRIPTION

[Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) is a thin wrapper around [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) that is
useful when you want to connect to different databases using slightly different
connection info. It also allows you to easily connect using different settings in
different environments by using environment variables to connect (see ["ATTRIBUTES"](#attributes)).
This can be useful when developing using something like [Docker](https://www.docker.com/),
which easily allows you to set different environment variables in dev/prod.

[Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) is a shell class that just composes [Mojo::DB::Connector::Base](https://metacpan.org/pod/Mojo::DB::Connector::Base):

    with 'Mojo::DB::Connector::Base';

You may use [Mojo::DB::Connector::Base](https://metacpan.org/pod/Mojo::DB::Connector::Base) as a starting point for your own DB Connectors,
if needed.

See [Mojo::DB::Connector::Role::Cache](https://metacpan.org/pod/Mojo::DB::Connector::Role::Cache) for the ability to cache connections.

# ATTRIBUTES

## env\_prefix

    my $connector = Mojo::DB::Connector->new(env_prefix => 'MOJO_DB_CONNECTOR_');

    my $env_prefix = $connector->env_prefix;
    $connector     = $connector->env_prefix('MOJO_DB_CONNECTOR_');

The prefix that will be used for environment variables names when checking for default values.
The prefix will go before:

- [SCHEME](#scheme)
- [USERINFO](#userinfo)
- [HOST](#host)
- [PORT](#port)
- [DATABASE](#database)
- [OPTIONS](#options)
- [URL](#url)
- [STRICT\_MODE](#strict_mode)

["env\_prefix"](#env_prefix) allows you to use different [Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) objects to easily generate connections
for different connection settings.

Default is `MOJO_DB_CONNECTOR_`.

## scheme

    my $scheme = $connector->scheme;
    $connector = $connector->scheme('postgresql');

The ["scheme" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#scheme) that will be used for generating the connection URL.
Allowed values are [mariadb](https://metacpan.org/pod/DBD::MariaDB), [mysql](https://metacpan.org/pod/DBD::mysql), and [postgresql](https://metacpan.org/pod/DBD::Pg). The scheme
will determine whether a [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) or [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) instance is returned. `mariadb` and `mysql`
indicate [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql), and `postgresql` indicates [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg).

This can also be derived from ["scheme" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#scheme) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_SCHEME`.

Default is first derived from ["scheme" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#scheme) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_SCHEME}`, and then falls back to `postgresql`.

## userinfo

    my $userinfo = $connector->userinfo;
    $connector   = $connector->userinfo('sri:s3cret');

The ["userinfo" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#userinfo) that will be used for generating the connection URL.

This can also be derived from ["userinfo" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#userinfo) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_USERINFO`.

Default is first derived from ["userinfo" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#userinfo) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_USERINFO}`, and then falls back to no `userinfo` (empty string).

## host

    my $host   = $connector->host;
    $connector = $connector->host('localhost');

The ["host" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#host) that will be used for generating the connection URL.

This can also be derived from ["host" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#host) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_HOST`.

Default is first derived from ["host" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#host) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_HOST}`, and then falls back to `localhost`.

## port

    my $port   = $connector->port;
    $connector = $connector->port(5432);

The ["port" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#port) that will be used for generating the connection URL.

This can also be derived from ["port" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#port) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_PORT`.

Default is first derived from ["port" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#port) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_PORT}`, and then falls back to `5432`.

## database

    my $database = $connector->database;
    $connector   = $connector->database('my_database');

The database that will be used for generating the connection URL. This will be used
as ["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path).

This can also be derived from ["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_DATABASE`.

Default is first derived from ["path" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#path) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_DATABASE}`, and then falls back to no `database` (empty string).

## options

    my $options = $connector->options;
    $connector  = $connector->options([PrintError => 1, RaiseError => 0]);

    # hashref also accepted
    $connector  = $connector->options({PrintError => 1, RaiseError => 0});

The options that will be used as the parameters ([Mojo::Parameters](https://metacpan.org/pod/Mojo::Parameters)) for generating the connection URL. This will be used
as ["query" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#query). This accepts any valid input for ["query" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#query) except a list.

This can also be derived from ["query" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#query) via ["url"](#url) or set with the environment variable `MOJO_DB_CONNECTOR_OPTIONS`.

When set with the environment variable `MOJO_DB_CONNECTOR_OPTIONS`, ["options"](#options) must be specified in
valid URL parameter syntax:

    $ENV{MOJO_DB_CONNECTOR_OPTIONS} = 'PrintError=1&RaiseError=0';

Default is first derived from ["query" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#query) via `$ENV{MOJO_DB_CONNECTOR_URL}`,
then `$ENV{MOJO_DB_CONNECTOR_OPTIONS}`, and then falls back to `[]` (no options).

## url

    my $url    = $connector->url;
    $connector = $connector->url('postgres://sri:s3cret@localhost/db3?PrintError=1&RaiseError=0');

The connection URL from which all other attributes can be derived (except ["strict\_mode"](#strict_mode)).
["url"](#url) must be specified before the first call to ["new\_connection"](#new_connection) is made, otherwise it will have no effect on setting the defaults.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_URL`.

Default is `$ENV{MOJO_DB_CONNECTOR_URL}` and then falls back to `undef` (no URL).

## strict\_mode

    my $strict_mode = $connector->strict_mode;
    $connector      = $connector->strict_mode(1);

["strict\_mode"](#strict_mode) determines if connections should be created in ["strict\_mode" in Mojo::mysql](https://metacpan.org/pod/Mojo::mysql#strict_mode).

Note that this only applies to [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and does **not** apply to [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg).
If a [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) connection is created, this will have no effect.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_STRICT_MODE`.

Default is `$ENV{MOJO_DB_CONNECTOR_STRICT_MODE}` and falls back to `1`

# METHODS

## new\_connection

    # use environment variables or defaults
    my $connection = $connector->new_connection;
    my $results    = $connection->db->query(...);

    # provide attribute overrides just for this call
    my $connection = $connector->new_connection(database => 'my_database', host => 'batman.com');
    my $results    = $connection->db->query(...);

["new\_connection"](#new_connection) creates a new connection ([Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) or [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) instance) using
either the connection info in ["ATTRIBUTES"](#attributes), or any override values passed.

Any override values that are passed will completely replace any values in ["ATTRIBUTES"](#attributes):

    my $connection = $connector->new_connection(database => 'my_database', host => 'batman.com');
    my $results    = $connection->db->query(...);

Except for ["options"](#options). ["options"](#options) follows the same format as ["query" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#query):

    # merge with existing options in attribute options by using a hashref
    my $connection = $connector->new_connection(options => {merge => 'to'});

    # append to existing options in attribute options by using an arrayref
    my $connection = $connector->new_connection(options => [append => 'with']);

    # replace existing options completely by passing replace_options => 1
    # must provide an arrayref for replace_options
    my $connection = $connector->new_connection(options => [append => 'with'], replace_options => 1);

`replace_options` is needed because you cannot pass a list for the `options` value. If `replace_options`
is provided, the `options` parameter must be an arrayref.

See ["options" in Mojo::mysql](https://metacpan.org/pod/Mojo::mysql#options) or ["options" in Mojo::Pg](https://metacpan.org/pod/Mojo::Pg#options).

# SEE ALSO

- [Mojo::DB::Connector::Base](https://metacpan.org/pod/Mojo::DB::Connector::Base)
- [Mojo::DB::Connector::Role::Cache](https://metacpan.org/pod/Mojo::DB::Connector::Role::Cache)
- [Mojo::DB::Connector::Role::ResultsRoles](https://metacpan.org/pod/Mojo::DB::Connector::Role::ResultsRoles)

    Apply roles to Mojo database results from [Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) connections.

- [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql)
- [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)

# LICENSE

This software is copyright (c) 2020 by Adam Hopkins

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Adam Hopkins <srchulo@cpan.org>
