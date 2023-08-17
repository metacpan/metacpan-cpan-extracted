#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Register;
use Plack::Runner;
use Tags::Output::Indent;

# Run application.
my $app = Plack::App::Register->new(
        'css' => CSS::Struct::Output::Indent->new,
        'generator' => 'Plack::App::Register',
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
#     <meta name="generator" content="Plack::App::Register" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Register page
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
# .form-register {
# 	width: 300px;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-register fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-register legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-register p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-register label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-register input[type="text"], .form-register input[type="password"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-register button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-register button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# .form-register .messages {
# 	text-align: center;
# }
# .info {
# 	color: blue;
# }
# .error {
# 	color: red;
# }
# </style>
#   </head>
#   <body>
#     <div class="container">
#       <div class="inner">
#         <form class="form-register" method="post">
#           <fieldset>
#             <legend>
#               Register
#             </legend>
#             <p>
#               <label for="username" />
#               User name
#               <input type="text" name="username" id="username" />
#             </p>
#             <p>
#               <label for="password1">
#                 Password #1
#               </label>
#               <input type="password" name="password1" id="password1" />
#             </p>
#             <p>
#               <label for="password2">
#                 Password #2
#               </label>
#               <input type="password" name="password2" id="password2" />
#             </p>
#             <p>
#               <button type="submit" name="register" value="register">
#                 Register
#               </button>
#             </p>
#           </fieldset>
#         </form>
#       </div>
#     </div>
#   </body>
# </html>