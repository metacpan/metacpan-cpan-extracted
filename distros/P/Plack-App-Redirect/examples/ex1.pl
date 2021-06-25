#!/usr/bin/env perl

use strict;
use warnings;

use Plack::App::Redirect;
use Plack::Runner;

# Run application.
my $app = Plack::App::Redirect->new(
        'redirect_url' => 'https://skim.cz',
)->to_app;
Plack::Runner->new->run($app);

# Output (HEAD on redirected site):
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# HEAD http://localhost:5000/
# 200 OK
# Connection: close
# Date: Wed, 16 Jun 2021 15:41:44 GMT
# Server: nginx/1.17.6
# Content-Length: 3543
# Content-Type: text/html; charset=utf-8
# Last-Modified: Tue, 15 Jun 2021 22:16:46 GMT
# Client-Date: Wed, 16 Jun 2021 15:41:44 GMT
# Client-Peer: 89.185.227.162:443
# Client-Response-Num: 1
# Client-SSL-Cert-Issuer: /C=US/O=Let's Encrypt/CN=R3
# Client-SSL-Cert-Subject: /CN=skim.cz
# Client-SSL-Cipher: TLS_AES_256_GCM_SHA384
# Client-SSL-Socket-Class: IO::Socket::SSL
# Strict-Transport-Security: max-age=31536000