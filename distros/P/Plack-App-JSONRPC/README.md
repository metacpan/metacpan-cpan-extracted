[![Build Status](https://travis-ci.org/nqounet/p5-plack-app-jsonrpc.png?branch=master)](https://travis-ci.org/nqounet/p5-plack-app-jsonrpc)
# NAME

Plack::App::JSONRPC - (DEPRECATED) Yet another JSON-RPC 2.0 psgi application

# SYNOPSIS

    # app.psgi
    use Plack::App::JSONRPC;
    use Plack::Builder;
    my $jsonrpc = Plack::App::JSONRPC->new(
        methods => {
            echo  => sub { $_[0] },
            empty => sub {''}
        }
    );
    my $app = sub { [204, [], []] };
    builder {
        mount '/jsonrpc', $jsonrpc->to_app;
        mount '/' => $app;
    };

    # run
    $ plackup app.psgi

    # POST http://localhost:5000/jsonrpc
    #     {"jsonrpc":"2.0","method":"echo","params":"Hello","id":1}
    # return content
    #     {"jsonrpc":"2.0","result":"Hello","id":1}

# DESCRIPTION

Plack::App::JSONRPC is Yet another JSON-RPC 2.0 psgi application

# LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

nqounet <mail@nqou.net>
