package Nephia::Plugin::Dispatch;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Router::Simple;

our $VERSION = "0.03";

sub exports {
    qw/get post put del path_param/;
}

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    my $app = $self->app;
    $app->action_chain->after('Core', Dispatch => $self->can('dispatch'));
    $app->{router} = Router::Simple->new;
    return $self;
}

sub dispatch {
    my ($app, $context) = @_;
    my $router = $app->{router};
    my $req    = $context->get('req');
    my $env    = $req->env;
    my $res    = $app->dsl('res_404') ? $app->dsl('res_404')->() : [404, [], ['not found']];
    if (my $p = $router->match($env) ) {
        my $action = delete $p->{action};
        $context->set(path_param => $p);
        $res = $action->($app, $context);
    }
    $context->set(res => $res);
    return $context;
}

sub path_param {
    my ($self, $context) = @_;
    return sub (;$) {
        my $path_param = $context->get('path_param');
        $_[0] ? $path_param->{$_[0]} : $path_param;
    };
}

sub path {
    my ($self, $context, $method) = @_;
    my $router = $self->app->{router};
    return sub ($;@) {
        my ($path, $code) = @_;
        my @pathes = ref($path) eq 'ARRAY' ? @$path : ( $path );
        $router->connect($_, {action => $code}, {method => $method}) for @pathes;
    };
}

{
    no strict qw/refs/;
    my %methods = (get => 'GET', post => 'POST', put => 'PUT', del => 'DELETE');
    for my $dsl (keys %methods) {
        *$dsl = sub {
            my ($self, $context) = @_;
            $self->path($context, $methods{$dsl});
        };
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Dispatch - Dispatcher Plugin for Nephia

=head1 DESCRIPTION

This plugin provides dispatcher feature to Nephia.

=head1 SYNOPSIS

    package My::NephiaApp;
    use Nephia plugins => ['Dispatch'];
    
    {   ### External Controller Class
        package My::NephiaApp::C::External;
        sub index {
            my $c = shift;             # Nephia::Core object
            my $id = $c->param('id');  # You may call param method via Nephia::Core object
            [200, [], ["id = $id"]];
        }
    };

    my $users = {};
    
    app {
        get '/' => sub { [200, [], 'Hello, World!'] };
        get '/user/:id' => sub {
            my $id = path_param('id');
            my $user = $users->{$id};
            $user ? 
                [200, [], sprintf('name = %s', $user->{name}) ]
                [404, [], 'no such user']
            ;
        };
        post '/user/:id' => sub {
            my $id = path_param('id');
            my $name = param('name'); 
            $users->{$id} = { name => $name };
            [200, [], 'registered!'];
        };
        get '/external/' => Nephia->call('C::External#index');
    };
    

=head1 DSL

=head2 get post put del

    get $path => sub { ... };

Add action for $path. You may use L<Router::Simple> syntax in $path.

=head2 path_param

    get '/user/:id' => sub {
        my $id = path_param('id');
        ### or 
        my $path_params = path_param;
        $id = $path_params->{id};
        ...
    };

Fetch captured parameter from PATH_INFO.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

