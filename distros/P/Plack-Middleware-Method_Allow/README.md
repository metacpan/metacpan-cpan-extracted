# NAME

Plack::Middleware::Method\_Allow - perl Plack Middleware to filter HTTP Methods

# SYNOPSIS

    builder {
      enable "Plack::Middleware::Method_Allow", allow=>['GET', 'POST'];
      $app;
    };

# DESCRIPTION

Explicitly allow HTTP methods and return 405 METHOD NOT ALLOWED for all others

# PROPERTIES

## allow

Method that set the allowed methods.  Must be an array reference of HTTP methods.

# METHODS

## prepare\_app

Method is called once at load to read the allow list.

## call

Method is called for each request which return 405 Method Not Allowed for any HTTP method that is not in list.

# SEE ALSO

[Plack::Middleware](https://metacpan.org/pod/Plack::Middleware)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis
