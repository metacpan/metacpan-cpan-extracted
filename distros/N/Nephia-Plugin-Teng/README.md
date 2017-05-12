[![Build Status](https://travis-ci.org/mackee/Nephia-Plugin-Teng.png?branch=master)](https://travis-ci.org/mackee/Nephia-Plugin-Teng)
# NAME

Nephia::Plugin::Teng - Simple ORMapper Plugin For Nephia

# SYNOPSIS

    use Nephia plugins => [qw/Teng/];

    path '/person/:id' => sub {
        my $id = path_param('id');
        my $row = teng->lookup('person', { id => $id });
        return res { 404 } unless $row;

        return {
            id => $id,
            name => $row->get_column('name'),
            age => $row->get_column('age'),
        };
    };

Read row from person table in database in this code.

# DESCRIPTION

## configuration - configuration for Teng.

configuration file:

    'DBI' => {
        connect_info => ['dbi:SQLite:dbname=data.db'],
        teng_plugins => [qw/Lookup Pager/]
    },

The "connect\_info" is connect information for [DBI](http://search.cpan.org/perldoc?DBI).

Enumerate in "plugins" option if you want load Teng plugins.

## teng - Create Teng Object

"teng" DSL create the Teng Object.

## database\_do - load SQL before plackup.

In this example to create table before plackup.

in controller :

    database_do "CREATE TABLE IF NOT EXISTS person (id INTEGER, name TEXT, age INTEGER);"

    path '/' => sub {
        ...
    };

# SEE ALSO

[Nephia](http://search.cpan.org/perldoc?Nephia)

[Teng](http://search.cpan.org/perldoc?Teng)

# LICENSE

Copyright (C) macopy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mackee <macopy123\[attttt\]gmai.com>

ichigotake
