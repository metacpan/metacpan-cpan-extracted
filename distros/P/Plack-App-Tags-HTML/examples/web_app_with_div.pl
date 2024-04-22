#!/usr/bin/env perl

use strict;
use warnings;

package App;

use base qw(Tags::HTML);

sub _process {
        my ($self, $value_hr) = @_;

        $self->{'tags'}->put(
                ['b', 'div'],
                ['a', 'class', 'my-class'],
                ['d', join ',', @{$value_hr->{'foo'}}],
                ['e', 'div'],
        );

        return;
}

sub _process_css {
        my $self = shift;

        $self->{'css'}->put(
                ['s', '.my-class'],
                ['d', 'border', '1px solid black'],
                ['e'],
        );

        return;
}

package main;

use CSS::Struct::Output::Indent;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::Output::Indent;

# Run application.
my $app = Plack::App::Tags::HTML->new(
        'component' => 'App',
        'css' => CSS::Struct::Output::Indent->new,
        'data' => [{
                'foo' => [1, 2],
        }],
        'tags' => Tags::Output::Indent->new(
                'preserved' => ['style'],
        ),
)->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
#     </meta>
#     <meta name="viewport" content="width=device-width, initial-scale=1.0">
#     </meta>
#     <style type="text/css">
# * {
# 	box-sizing: border-box;
# 	margin: 0;
# 	padding: 0;
# }
# .my-class {
# 	border: 1px solid black;
# }
# </style>
#   </head>
#   <body>
#     <div class="my-class">
#       1,2
#     </div>
#   </body>
# </html>