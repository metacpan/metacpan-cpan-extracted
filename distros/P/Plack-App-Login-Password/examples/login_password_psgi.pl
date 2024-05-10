#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Login::Password;
use Plack::Runner;
use Tags::Output::Indent;

# Run application.
my $app = Plack::App::Login::Password->new(
        'css' => CSS::Struct::Output::Indent->new,
        'generator' => 'Plack::App::Login::Password',
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
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
#     <meta name="generator" content="Plack::App::Login::Password"
#       />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Login page
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
# .form-login {
# 	width: 300px;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-login fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-login legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-login p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-login label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-login input[type="text"], .form-login input[type="password"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-login button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-login button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# </style>
#   </head>
#   <body>
#     <div class="container">
#       <div class="inner">
#         <form class="form-login" method="post">
#           <fieldset>
#             <legend>
#               Login
#             </legend>
#             <p>
#               <label for="username">
#                 User name
#               </label>
#               <input type="text" name="username" id="username" />
#             </p>
#             <p>
#               <label for="password">
#                 Password
#               </label>
#               <input type="password" name="password" id="password" />
#             </p>
#             <p>
#               <button type="submit" name="login" value="login">
#                 Login
#               </button>
#             </p>
#           </fieldset>
#         </form>
#       </div>
#     </div>
#   </body>
# </html>