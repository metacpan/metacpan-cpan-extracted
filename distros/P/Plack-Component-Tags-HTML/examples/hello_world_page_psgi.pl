#!/usr/bin/env perl

package App;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

sub _tags_middle {
        my $self = shift;

        $self->{'tags'}->put(
                ['d', 'Hello world'],
        );

        return;
}

package main;

use Plack::Runner;

my $app = App->new(
        'title' => 'My app',
)->to_app;
my $runner = Plack::Runner->new;
$runner->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# Output by HEAD to http://localhost:5000/:
# 200 OK
# Date: Sun, 31 Oct 2021 10:35:33 GMT
# Server: HTTP::Server::PSGI
# Content-Length: 166
# Content-Type: text/html; charset=utf-8
# Client-Date: Sun, 31 Oct 2021 10:35:33 GMT
# Client-Peer: 127.0.0.1:5000
# Client-Response-Num: 1

# Output by GET to http://localhost:5000/:
# <!DOCTYPE html>
# <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>My app</title></head><body>Hello world</body></html>