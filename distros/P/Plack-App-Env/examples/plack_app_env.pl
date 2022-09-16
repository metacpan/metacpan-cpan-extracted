#!/usr/bin/env perl

use strict;
use warnings;

use Plack::App::Env;
use Plack::Runner;

# Run application.
my $app = Plack::App::Env->new->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# \ {
#     HTTP_ACCEPT            "*/*",
#     HTTP_HOST              "localhost:5000",
#     HTTP_USER_AGENT        "curl/7.64.0",
#     PATH_INFO              "/",
#     psgi.errors            *main::STDERR  (read/write, layers: unix perlio),
#     psgi.input             *HTTP::Server::PSGI::$input  (layers: scalar),
#     psgi.multiprocess      "",
#     psgi.multithread       "",
#     psgi.nonblocking       "",
#     psgi.run_once          "",
#     psgi.streaming         1,
#     psgi.url_scheme        "http",
#     psgi.version           [
#         [0] 1,
#         [1] 1
#     ],
#     psgix.harakiri         1,
#     psgix.input.buffered   1,
#     psgix.io               *Symbol::GEN1  (read/write, layers: unix perlio),
#     QUERY_STRING           "",
#     REMOTE_ADDR            "127.0.0.1",
#     REMOTE_PORT            39562,
#     REQUEST_METHOD         "GET",
#     REQUEST_URI            "/",
#     SCRIPT_NAME            "",
#     SERVER_NAME            0,
#     SERVER_PORT            5000,
#     SERVER_PROTOCOL        "HTTP/1.1"
# }