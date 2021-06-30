# NAME

Mojolicious::Plugin::Model::DB - It is an extension of the module [Mojolicious::Plugin::Model](https://metacpan.org/pod/Mojolicious::Plugin::Model)
for Mojolicious applications

# SYNOPSIS

Model Functions

    package MyApp::Model::Functions;
    use Mojo::Base 'MojoX::Model';

    sub trim {
        my ($self, $value) = @_;

        $value =~ s/^\s+|\s+$//g;

        return $value;
    }

    1;

Model DB Person

    package MyApp::Model::DB::Person;
    use Mojo::Base 'MojoX::Model';

    sub save {
        my ($self, $foo) = @_;

        return $self->mysql->db->insert(
            'foo',
            {
                foo => $foo
            }
        )->last_insert_id;
    }

    1;

Mojolicious::Lite application

    #!/usr/bin/env perl
    use Mojolicious::Lite;

    use lib 'lib';

    plugin 'Model::DB' => {mysql => 'mysql://user@/mydb'};

    any '/' => sub {
        my $c = shift;

        my $foo = $c->param('foo')
                ? $c->model('functions')->trim($c->param('foo')) # model functions
                : '';

        # model db Person
        my $id = $c->db('person')->save($foo);

        $c->render(text => $id);
    };

    app->start;

All available options

    #!/usr/bin/env perl
    use Mojolicious::Lite;

    plugin 'Model::DB' => {
        # Mojolicious::Plugin::Model::DB
        namespace    => 'DataBase',                # default is DB

        # databases options
        Pg           => 'postgresql://user@/mydb', # this will instantiate Mojo::Pg, in model get $self->pg,
        mysql        => 'mysql://user@/mydb',      # this will instantiate Mojo::mysql, in model get $self->mysql,
        SQLite       => 'sqlite:test.db',          # this will instantiate Mojo::SQLite, in model get $self->sqlite,
        Redis        => 'redis://localhost',       # this will instantiate Mojo::Redis, in model get $self->redis,

        # Mojolicious::Plugin::Model
        namespaces   => ['MyApp::Model', 'MyApp::CLI::Model'],
        base_classes => ['MyApp::Model'],
        default      => 'MyApp::Model::Pg',
        params       => {Pg => {uri => 'postgresql://user@/mydb'}}
    };

# DESCRIPTION

[Mojolicious::Plugin::Model::DB](https://metacpan.org/pod/Mojolicious::Plugin::Model::DB) It is an extension of the module Mojolicious::Plugin::Model,
the intention is to separate models of database from other models, using Mojolicious::Plugin::Model::DB you can continue using all functions of Mojolicious::Plugin::Model.
See more in [Mojolicious::Plugin::Model](https://metacpan.org/pod/Mojolicious::Plugin::Model)

# OPTIONS

## namespace

    # Mojolicious::Lite
    plugin 'Model::DB' => {namespace => 'DataBase'}; # It's will load from $moniker::Model::DataBase

Namespace to load models from, defaults to `$moniker::Model::DB`.

## databases

#### Mojo::Pg

    # Mojolicious::Lite
    plugin 'Model::DB' => {Pg => 'postgresql://user@/mydb'};

    # Model::DB
    package MyApp::Model::DB::Foo;
    use Mojo::Base 'MojoX::Model';

    sub find {
        my ($self, $id) = @_;

        return $self->pg->db->select(
            'foo',
            undef,
            {
                id => $id
            }
        )->hash;
    }

    1;

#### Mojo::mysql

    # Mojolicious::Lite
    plugin 'Model::DB' => {mysql => 'mysql://user@/mydb'};

    # Model::DB
    package MyApp::Model::DB::Foo;
    use Mojo::Base 'MojoX::Model';

    sub find {
        my ($self, $id) = @_;

        return $self->mysql->db->select(
            'foo',
            undef,
            {
                id => $id
            }
        )->hash;
    }

    1;

#### Mojo::SQLite

    # Mojolicious::Lite
    plugin 'Model::DB' => {SQLite => 'sqlite:test.db'};

    # Model::DB
    package MyApp::Model::DB::Foo;
    use Mojo::Base 'MojoX::Model';

    sub find {
        my ($self, $id) = @_;

        return $self->sqlite->db->select(
            'foo',
            undef,
            {
                id => $id
            }
        )->hash;
    }

    1;

#### Mojo::Redis

    # Mojolicious::Lite
    plugin 'Model::DB' => {Redis => 'redis://localhost'};

    # Model::DB
    package MyApp::Model::DB::Foo;
    use Mojo::Base 'MojoX::Model';

    sub find {
        my ($self, $key) = @_;

        return $self->redis->db->get($key);
    }

    1;

#### Mojo::mysql and Mojo::Redis

    # Mojolicious::Lite
    plugin 'Model::DB' => {
        mysql => 'mysql://user@/mydb',
        Redis => 'redis://localhost'
    };

    # Model::DB
    package MyApp::Model::DB::Foo;
    use Mojo::Base 'MojoX::Model';

    sub find {
        my ($self, $id) = @_;

        my $cache = $self->redis->db->get('foo:' . $id);
        return $cache if $cache;

        my $foo = $self->mysql->db->select(
            'foo',
            undef,
            {
                id => $id
            }
        )->hash;

        $self->redis->db->set('foo:' . $id, $foo);

        return $foo;
    }

    1;



## more options

see in [Mojolicious::Plugin::Model#OPTIONS](https://metacpan.org/pod/Mojolicious::Plugin::Model#OPTIONS)

# HELPERS

[Mojolicious::Plugin::Model::DB](https://metacpan.org/pod/Mojolicious::Plugin::Model::DB) implements the following helpers.

## db

    my $db = $c->db($name);

Load, create and cache a model object with given name. Default class for
model db `camelize($moniker)::Model::DB`. Return `undef` if model db not found.

## more helpers

see in [Mojolicious::Plugin::Model#HELPERS](https://metacpan.org/pod/Mojolicious::Plugin::Model#HELPERS)

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides),
[http://mojolicio.us](http://mojolicio.us), [Mojolicious::Plugin::Model](https://metacpan.org/pod/Mojolicious::Plugin::Model).

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
