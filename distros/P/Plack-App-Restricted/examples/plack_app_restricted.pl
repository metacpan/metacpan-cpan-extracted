#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Restricted;
use Plack::Runner;
use Tags::Output::Indent;

# Run application.
my $app = Plack::App::Restricted->new(
        'css' => CSS::Struct::Output::Indent->new,
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
# .container {
# 	position: fixed;
# 	top: 50%;
# 	left: 50%;
# 	transform: translate(-50%, -50%);
# }
# .inner {
# 	text-align: center;
# }
# .restricted {
# 	color: red;
# 	font-family: sans-serif;
# 	font-size: 3em;
# }
# </style>
#   </head>
#   <body>
#     <div class="container">
#       <div class="inner">
#         <div class="restricted">
#           Restricted access
#         </div>
#       </div>
#     </div>
#   </body>
# </html>