package Mojolicious::Plugin::Model::DB;
use Mojo::Base 'Mojolicious::Plugin::Model';
use Mojo::Util 'camelize';
use Storable qw/dclone/;
use Class::Method::Modifiers qw/after/;

our $VERSION = '0.09';

after register => sub {
    my ($plugin, $app, $conf) = @_;
    
    $conf = dclone $conf;
    my $namespace  = $conf->{namespace}  // 'DB';
    my $namespaces = $conf->{namespaces} // [camelize($app->moniker) . '::Model'];
    @{$conf->{namespaces}} = map $_ . "::$namespace", @$namespaces;       
    
    $app->helper(
        db => sub {
            my ($self, $name) = @_;
            $name //= $conf->{default};
            
            my $model;
            return $model if $model = $plugin->{models}{$name};         
            
            my $class = Mojolicious::Plugin::Model::_load_class_for_name($plugin, $app, $conf, $name)
                or return undef;
            
            my $params = $conf->{params}{$name};
            $model = $class->new(ref $params eq 'HASH' ? %$params : (), app => $app);
            $plugin->{models}{$name} = $model;
            return $model;
        }
    );    
};

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Model::DB - It is an extension of the module L<Mojolicious::Plugin::Model> for Mojolicious applications. 

=head1 SYNOPSIS

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
        
        # model db
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
    
=head1 DESCRIPTION

Mojolicious::Plugin::Model::DB It is an extension of the module Mojolicious::Plugin::Model, the intention is to separate models of database from other models. See more in L<Mojolicious::Plugin::Model>

=head1 OPTIONS

=head2 namespace

    # Mojolicious::Lite
    plugin 'Model::DB' => {namespace => 'DataBase'}; # It's will load from $moniker::Model::DataBase
    
Namespace to load models from, defaults to C<$moniker::Model::DB>.

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