#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Plack::App::Search;
use Plack::Runner;
use Tags::Output::Indent;

# Run application.
my $app = Plack::App::Search->new(
        'css' => CSS::Struct::Output::Indent->new,
        'generator' => 'Plack::App::Search',
        'search_title' => 'Search',
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
#     <meta name="generator" content="Plack::App::Search" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Search page
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
# .search form {
# 	display: flex;
# 	align-items: center;
# }
# .search input[type="text"] {
# 	padding: 10px;
# 	border-radius: 4px;
# 	border: 1px solid #ccc;
# }
# .search button {
# 	margin-left: 10px;
# 	padding: 10px 20px;
# 	border-radius: 4px;
# 	background-color: #4CAF50;
# 	color: white;
# 	border: none;
# 	cursor: pointer;
# }
# .search button:hover {
# 	background-color: #45a049;
# }
# </style>
#   </head>
#   <body>
#     <div class="container">
#       <div class="search">
#         <form method="get" action="https://env.skim.cz">
#           <input type="text" autofocus="autofocus" />
#           <button type="submit">
#             Search
#           </button>
#         </form>
#       </div>
#     </div>
#   </body>
# </html>