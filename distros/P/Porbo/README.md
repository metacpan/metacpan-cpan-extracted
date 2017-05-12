# NAME

Porbo - Porbo HTTP development psgi server

# SYNOPSIS

    plackup -s Porbo \
            --listen http://127.0.0.1:3000 \
            --listen https://127.0.0.1:3001 \
            --ssl-key-file tools/server.key \
            --ssl-cert-file tools/server.crt \
            app.psgi

# DESCRIPTION

Porbo is a standalone, single-process and PSGI compatible HTTP server implementations.

This server should be great for the development and testing, but might not be suitable for a production use.

This server supports listening on multi ports and TLS like [Mojo::Server::Morbo](https://metacpan.org/pod/Mojo::Server::Morbo).

# LICENSE

Copyright (C) Uchiko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Uchiko <memememomo@gmail.com>
