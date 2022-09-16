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
        'flag_begin' => 0,
        'flag_end' => 0,
        'title' => 'My app',
)->to_app;
my $runner = Plack::Runner->new;
$runner->run($app);

# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# Output by HEAD to http://localhost:5000/:
# 200 OK
# Date: Sun, 27 Feb 2022 18:52:59 GMT
# Server: HTTP::Server::PSGI
# Content-Length: 11
# Content-Type: text/html; charset=utf-8
# Client-Date: Sun, 27 Feb 2022 18:52:59 GMT
# Client-Peer: 127.0.0.1:5000
# Client-Response-Num: 1

# Output by GET to http://localhost:5000/:
# Hello world