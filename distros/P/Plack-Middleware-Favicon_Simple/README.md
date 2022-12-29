# NAME

Plack::Middleware::Favicon\_Simple - Perl Plack Middleware to provide favicon

# SYNOPSIS

    use Plack::Builder qw{builder mount enable};
    builder {
      enable "Plack::Middleware::Favicon_Simple";
      $app;
    };

# DESCRIPTION

Browsers request /favicon.ico automatically.  This Plack Middleware returns a favicon.ico file so that browsers do not get 404 HTTP codes.

# METHODS

## call

Middleware wrapper method.

## favicon

Sets the favicon from a binary source.

    builder {
      enable "Plack::Middleware::Favicon_Simple", favicon=>$binary_blob;
      $app;
    };

Default is a blank icon.

# SEE ALSO

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware), [Plack::Middleware::Favicon](https://metacpan.org/pod/Plack::Middleware::Favicon)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis
