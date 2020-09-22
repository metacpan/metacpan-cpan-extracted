#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Login;
use Plack::Runner;
use Tags::Output::Indent;

# Run application with one PYX file.
my $app = Plack::App::Login->new(
        'css' => CSS::Struct::Output::Indent->new,
        'tags' => Tags::Output::Indent->new(
                'preserved' => ['style'],
                'xml' => 1,
        ),
)->to_app;
Plack::Runner->new->run($app);

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# <!DOCTYPE html>
# <html>
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#     <meta charset="UTF-8" />
#     <meta name="generator" content=
#       "Perl module: Tags::HTML::Page::Begin, Version: 0.08" />
#     <title>
#       Login page
#     </title>
#     <style type="text/css">
# .outer {
#         position: fixed;
#         top: 50%;
#         left: 50%;
#         transform: translate(-50%, -50%);
# }
# .login {
#         text-align: center;
#         background-color: blue;
#         padding: 1em;
# }
# .login a {
#         text-decoration: none;
#         color: white;
#         font-size: 3em;
# }
# </style>
#   </head>
#   <body class="outer">
#     <div class="login">
#       <a href="login">
#         LOGIN
#       </a>
#     </div>
#   </body>
# </html>