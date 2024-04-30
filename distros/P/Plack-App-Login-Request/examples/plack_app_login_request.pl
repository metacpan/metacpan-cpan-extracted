#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Login::Request;
use Data::Message::Simple;
use Plack::Builder;
use Plack::Runner;
use Plack::Session;
use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8);

my $message_cb = sub {
        my ($env, $message_type, $message) = @_;
        my $session = Plack::Session->new($env);
        my $m = Data::Message::Simple->new(
                'text' => $message,
                'type' => $message_type,
        );
        my $messages_ar = $session->get('messages');
        if (defined $messages_ar) {
                push @{$messages_ar}, $m;
        } else {
                $session->set('messages', [$m]);
        }
        return;
};

# Run application.
my $app = Plack::App::Login::Request->new(
        'css' => CSS::Struct::Output::Indent->new,
        'generator' => 'Plack::App::Login::Request',
        'login_request_cb' => sub {
                my ($env, $email) = @_;
                if ($email eq 'skim@skim.cz') {
                        return 1;
                } else {
                        return 0;
                }
        },
        'message_cb' => $message_cb,
        'redirect_login' => '/',
        'redirect_error' => '/',
        'tags' => Tags::Output::Indent->new(
                'preserved' => ['style'],
                'xml' => 1,
        ),
)->to_app;
my $builder = Plack::Builder->new;
$builder->add_middleware('Session');
my $app_with_session = $builder->wrap($app);
Plack::Runner->new->run($app_with_session);

# Workflows:
# 1) Blank request.
# 2) Fill skim@skim.cz email and request.
# 3) Fill another email and request.

# Output:
# HTTP::Server::PSGI: Accepting connections at http://0:5000/

# > curl http://localhost:5000/
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
#     <meta name="generator" content="Plack::App::Login::Request" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Login request page
#     </title>
#     <style type="text/css">
# * {
# 	box-sizing: border-box;
# 	margin: 0;
# 	padding: 0;
# }
# .container {
# 	display: flex;
# 	align-items: center;
# 	justify-content: center;
# 	height: 100vh;
# }
# .form-request {
# 	width: 300px;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-request .logo {
# 	height: 5em;
# 	width: 100%;
# }
# .form-request img {
# 	margin: auto;
# 	display: block;
# 	max-width: 100%;
# 	max-height: 5em;
# }
# .form-request fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-request legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-request p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-request label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-request input[type="email"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-request button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-request button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# .form-request .messages {
# 	text-align: center;
# }
# .error {
# 	color: red;
# }
# .info {
# 	color: blue;
# }
# </style>
#   </head>
#   <body>
#     <div class="container">
#       <div class="inner">
#         <form class="form-request" method="post">
#           <fieldset>
#             <legend>
#               Login request
#             </legend>
#             <p>
#               <label for="email" />
#               Email
#               <input type="email" name="email" id="email" autofocus="autofocus"
#                 />
#             </p>
#             <p>
#               <button type="submit" name="login_request" value="login_request">
#                 Request
#               </button>
#             </p>
#           </fieldset>
#         </form>
#       </div>
#     </div>
#   </body>
# </html>

# Output screenshot is in images/ directory.