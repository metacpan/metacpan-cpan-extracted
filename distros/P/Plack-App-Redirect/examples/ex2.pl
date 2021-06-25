#!/usr/bin/env perl

use strict;
use warnings;

use Plack::App::Redirect;
use Plack::Runner;

# Run application.
my $app = Plack::App::Redirect->new->to_app;
Plack::Runner->new->run($app);

# Output (HEAD on error from app):
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# HEAD http://localhost:5000/
# 404 Not Found
# Date: Wed, 16 Jun 2021 15:40:40 GMT
# Server: HTTP::Server::PSGI
# Content-Length: 1
# Content-Type: text/html; charset=utf-8
# Client-Date: Wed, 16 Jun 2021 15:40:40 GMT
# Client-Peer: 127.0.0.1:5000
# Client-Response-Num: 1