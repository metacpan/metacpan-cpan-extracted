# NAME

Plack::Middleware::Redirect - A simple redirector

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Redirect', url_patterns => [
            '/from/oldpath' => '/to/newpath',
            '/from/oldpath' => ['/to/newpath', 301],
            '/from/oldpath' => [sub {
                my ($env, $regex) = @_;
                my $path  = $env->{PATH_INFO};
                $path =~ m|$regex|;
                $path = join ("_", split("", $1)) if $1;
                my $newpath = "/"
                }, 302],
            '/foo/(.+)' => '/another/$1'
        ];
    };

# DESCRIPTION

A plack middleware that redirects.

# REPOSITORY

Plack::Middleware::Redirect is hosted on github: [https://github.com/okazu-dm/p5-plack-middleware-redirect/tree/master/lib/Plack/Middleware](https://github.com/okazu-dm/p5-plack-middleware-redirect/tree/master/lib/Plack/Middleware)

# LICENSE

Copyright (C) okazu-dm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

okazu-dm <uhavetwocows@gmail.com>
