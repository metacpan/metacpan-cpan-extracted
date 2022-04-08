#!/usr/bin/env perl

use strict;
use warnings;

use Plack::App::Data::Printer;
use Plack::Runner;

# Run application.
my $app = Plack::App::Data::Printer->new(
        'data' => {
                'example' => [1, 2, {
                        'foo' => 'bar',
                }, 5],
        },
)->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# {
#     example   [
#         [0] 1,
#         [1] 2,
#         [2] {
#                 foo   "bar"
#             },
#         [3] 5
#     ]
# }