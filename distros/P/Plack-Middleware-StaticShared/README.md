# NAME

Plack::Middleware::StaticShared - concat some static files to one resource

# SYNOPSIS

    use Plack::Builder;
    use WebService::Google::Closure;

    builder {
        enable "StaticShared",
            cache => Cache::Memcached::Fast->new(servers => [qw/192.168.0.11:11211/]),
            base  => './static/',
            binds => [
                {
                    prefix       => '/.shared.js',
                    content_type => 'text/javascript; charset=utf8',
                    filter       => sub {
                        WebService::Google::Closure->new(js_code => $_)->compile->code;
                    }
                },
                {
                    prefix       => '/.shared.css',
                    content_type => 'text/css; charset=utf8',
                }
            ];
            verifier => sub {
                my ($version, $prefix) = @_;
                $version =~ /v\d/
            },

        $app;
    };

And concatnated resources are provided as like following:

    /.shared.js:v1:/js/foolib.js,/js/barlib.js,/js/app.js
        => concat following: ./static/js/foolib.js, ./static/js/barlib.js, ./static/js/app.js

# DESCRIPTION

Plack::Middleware::StaticShared provides resource end point which concat some static files to one resource for reducing http requests.

# CONFIGURATIONS

- cache (required)

    A cache object for caching concatnated resource content.

- base (required)

    Base directory which concatnating resource located in.

- binds (required)

    Definition of concatnated resources.

- verifier (optional)

    A subroutine for verifying version string to avoid attacking of cache flooding.

# AUTHOR

cho45

# SEE ALSO

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware) [Plack::Builder](https://metacpan.org/pod/Plack::Builder)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
