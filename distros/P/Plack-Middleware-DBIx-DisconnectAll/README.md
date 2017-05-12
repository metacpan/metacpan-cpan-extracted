# NAME

Plack::Middleware::DBIx::DisconnectAll - Disconnect all database connection at end of request

# SYNOPSIS

    use Plack::Middleware::DBIx::DisconnectAll;

    use Plack::Builder;
    

    builder {
        enable "DBIx::DisconnectAll";
        $app
    };



# DESCRIPTION

Plack::Middleware::DBIx::DisconnectAll calls DBIx::DisconnectAll at end of request
and disconnects all database connections.

This modules is useful for freeing resources.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

# SEE ALSO

[DBIx::DisconnectAll](http://search.cpan.org/perldoc?DBIx::DisconnectAll)

# LICENSE

Copyright (C) Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
