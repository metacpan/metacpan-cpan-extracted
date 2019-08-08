# NAME
 
Mojolicious::Plugin::Model::DB - It is an extension of the module [Mojolicious::Plugin::Model](https://metacpan.org/pod/Mojolicious::Plugin::Model)
for Mojolicious applications

# SYNOPSIS

Model DB Person
 
    package MyApp::Model::DB::Person;
    use Mojo::Base 'MojoX::Model';
 
    sub save {
        my ($self, $foo) = @_;
        
        $mysql->db->insert(
            'foo',
            {
                foo => $foo
            }
        );
    }
 
    1;
    
Mojolicious::Lite application
 
    #!/usr/bin/env perl
    use Mojolicious::Lite;
 
    use lib 'lib';
 
    plugin 'Model::DB';
 
    any '/' => sub {
        my $c = shift;
 
        my $foo = $c->param('foo') || '';
        
        $c->db('person')->save($foo);
        
        $c->render(text => 'Save person foo');
    };
 
    app->start;
    
All available options

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    
    plugin 'Model::DB' => {
        # Mojolicious::Plugin::Model::DB
        namespace => 'DataBase', # default is DB
    
        # Mojolicious::Plugin::Model
        namespaces   => ['MyApp::Model', 'MyApp::CLI::Model'],
        base_classes => ['MyApp::Model'],
        default      => 'MyApp::Model::Pg',
        params => {Pg => {uri => 'postgresql://user@/mydb'}}
    };
    
# DESCRIPTION
 
[Mojolicious::Plugin::Model::DB](https://metacpan.org/pod/Mojolicious::Plugin::Model::DB) It is an extension of the module Mojolicious::Plugin::Model,
the intention is to separate models of database from other models. See more in [Mojolicious::Plugin::Model](https://metacpan.org/pod/Mojolicious::Plugin::Model)

# OPTIONS

## namespace
 
    # Mojolicious::Lite
    plugin 'Model::DB' => {namespace => 'DataBase'}; # It's will load from $moniker::Model::DataBase
    
Namespace to load models from, defaults to `$moniker::Model::DB`.

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