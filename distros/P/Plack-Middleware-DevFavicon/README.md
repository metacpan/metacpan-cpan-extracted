# NAME

Plack::Middleware::DevFavicon - Shows gray favicon for development env

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'DevFavicon';
        ...;
    };

# DESCRIPTION

Plack::Middleware::DevFavicon shows gray favicon for a specific environment
in order to distinguish the production environment.

# LICENSE

Copyright (C) Fuji, Goro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Fuji, Goro <gfuji@cpan.org>
