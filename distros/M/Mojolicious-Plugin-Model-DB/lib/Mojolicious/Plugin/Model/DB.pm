package Mojolicious::Plugin::Model::DB;
use Mojo::Base 'Mojolicious::Plugin::Model';
use Mojo::Util 'camelize';
use Mojo::Loader qw/load_class/;
use Storable qw/dclone/;
use Class::Method::Modifiers qw/after/;

our $VERSION = '1.03';

has 'databases' => sub {
    [qw/Pg mysql SQLite Redis/]
};

after register => sub {
    my ($plugin, $app, $conf) = @_;

    $conf = dclone $conf;

    # check if need camelize moniker
    my $path = $app->home . '/lib/' . $app->moniker;
    $app->moniker(camelize($app->moniker)) unless -d $path;

    my $namespace  = $conf->{namespace}  // 'DB';
    my $namespaces = $conf->{namespaces} // [$app->moniker . '::Model'];
    @{$conf->{namespaces}} = map $_ . "::$namespace", @$namespaces;
    my $databases = _load_class_databases($plugin, $conf);

    $app->helper(
        db => sub {
            my ($self, $name) = @_;
            $name //= $conf->{default};

            my $model;
            return $model if $model = $plugin->{models}{$name};

            my $class = Mojolicious::Plugin::Model::_load_class_for_name($plugin, $app, $conf, $name)
                or return undef;

            # define attr to database
            $class->attr($_) for keys %{$databases};

            my $params = $conf->{params}{$name};
            $model = $class->new(
                ref $params eq 'HASH' ? %$params : (),
                %$databases,
                app => $app
            );
            $plugin->{models}{$name} = $model;
            return $model;
        }
    );
};

sub _load_class_databases {
    my ($plugin, $conf) = @_;

    my $databases = {};

    for (@{$plugin->databases}) {
        if (defined $conf->{$_}) {
            my $class = 'Mojo::' . $_;
            my $e     = load_class $class;

            $databases->{lc($_)} = $class->new($conf->{$_});
        }
    }

    return $databases;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Model::DB - It is an extension of the module L<Mojolicious::Plugin::Model> for Mojolicious applications.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Mojolicious::Plugin::Model::DB It is an extension of the module Mojolicious::Plugin::Model, the intention is to separate models of database from other models,
using Mojolicious::Plugin::Model::DB you can continue using all functions of Mojolicious::Plugin::Model. See more in L<Mojolicious::Plugin::Model>.

=head1 OPTIONS

=head2 namespace

    # Mojolicious::Lite
    plugin 'Model::DB' => {namespace => 'DataBase'}; # It's will load from $moniker::Model::DataBase

Namespace to load models from, defaults to C<$moniker::Model::DB>.

=head2 databases

=head3 Mojo::Pg

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

=head3 Mojo::mysql

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

=head3 Mojo::SQLite

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

=head3 Mojo::Redis

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

=head3 Mojo::mysql and Mojo::Redis

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

=head2 more options

see in L<Mojolicious::Plugin::Model#OPTIONS>

=head1 HELPERS

L<Mojolicious::Plugin::Model::DB> implements the following helpers.

=head2 db

    my $db = $c->db($name);

Load, create and cache a model object with given name. Default class for
model db C<camelize($moniker)::Model::DB>. Return `undef` if model db not found.

=head2 more helpers

see in L<Mojolicious::Plugin::Model#HELPERS>

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicio.us>, L<Mojolicious::Plugin::Model>.

=head1 AUTHOR

Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
