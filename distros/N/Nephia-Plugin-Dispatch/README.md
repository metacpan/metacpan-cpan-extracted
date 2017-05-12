# NAME

Nephia::Plugin::Dispatch - Dispatcher Plugin for Nephia

# DESCRIPTION

This plugin provides dispatcher feature to Nephia.

# SYNOPSIS

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
    



# DSL

## get post put del

    get $path => sub { ... };

Add action for $path. You may use [Router::Simple](http://search.cpan.org/perldoc?Router::Simple) syntax in $path.

## path\_param

    get '/user/:id' => sub {
        my $id = path_param('id');
        ### or 
        my $path_params = path_param;
        $id = $path_params->{id};
        ...
    };

Fetch captured parameter from PATH\_INFO.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
