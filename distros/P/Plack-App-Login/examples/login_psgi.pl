#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Login;
use Plack::Runner;
use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8);

# Run application.
my $app = Plack::App::Login->new(
        'css' => CSS::Struct::Output::Indent->new,
        'generator' => 'Plack::App::Login',
        'login_title' => decode_utf8('Přihlašovací stránka'),
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
#     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
#     <meta name="generator" content="Plack::App::Login" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Login page
#     </title>
#     <style type="text/css">
# * {
#         box-sizing: border-box;
#         margin: 0;
#         padding: 0;
# }
# .outer {
#         position: fixed;
#         top: 50%;
#         left: 50%;
#         transform: translate(-50%, -50%);
# }
# .login {
#         text-align: center;
# }
# .login a {
#         text-decoration: none;
#         background-image: linear-gradient(to bottom,#fff 0,#e0e0e0 100%);
#         background-repeat: repeat-x;
#         border: 1px solid #adadad;
#         border-radius: 4px;
#         color: black;
#         font-family: sans-serif!important;
#         padding: 15px 40px;
# }
# .login a:hover {
#         background-color: #e0e0e0;
#         background-image: none;
# }
# </style>
#   </head>
#   <body class="outer">
#     <div class="login">
#       <a href="login">
#         Přihlašovací stránka
#       </a>
#     </div>
#   </body>
# </html>