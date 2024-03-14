#!/usr/bin/env perl

use strict;
use warnings;

use CPAN::Changes;
use CPAN::Changes::Entry;
use CPAN::Changes::Release;
use CSS::Struct::Output::Indent;
use Plack::App::CPAN::Changes;
use Plack::Runner;
use Tags::Output::Indent;

my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
        'releases' => [
                CPAN::Changes::Release->new(
                        'entries' => [
                                CPAN::Changes::Entry->new(
                                        'entries' => [
                                                'item #1',
                                        ],
                                        'text' => '',
                                ),
                                CPAN::Changes::Entry->new(
                                        'entries' => [
                                                'item #2',
                                        ],
                                        'text' => 'Foo',
                                ),
                        ],
                        'version' => 0.01,
                ),
        ],
);

# Run application.
my $app = Plack::App::CPAN::Changes->new(
        'css' => CSS::Struct::Output::Indent->new,
        'changes' => $changes,
        'generator' => 'Plack::App::CPAN::Changes',
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
#     <meta name="generator" content="Plack::App::CPAN::Changes" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Changes
#     </title>
#     <style type="text/css">
# * {
# 	box-sizing: border-box;
# 	margin: 0;
# 	padding: 0;
# }
# .changes {
# 	max-width: 800px;
# 	margin: auto;
# 	background: #fff;
# 	padding: 20px;
# 	border-radius: 8px;
# 	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
# }
# .changes .version {
# 	border-bottom: 2px solid #eee;
# 	padding-bottom: 20px;
# 	margin-bottom: 20px;
# }
# .changes .version:last-child {
# 	border-bottom: none;
# }
# .changes .version h2, .changes .version h3 {
# 	color: #007BFF;
# 	margin-top: 0;
# }
# .changes .version-changes {
# 	list-style-type: none;
# 	padding-left: 0;
# }
# .changes .version-change {
# 	background-color: #f8f9fa;
# 	margin: 10px 0;
# 	padding: 10px;
# 	border-left: 4px solid #007BFF;
# 	border-radius: 4px;
# }
# </style>
#   </head>
#   <body>
#     <div class="changes">
#       <h1>
#         Revision history for perl module Foo::Bar
#       </h1>
#       <div class="version">
#         <h2>
#           0.01
#         </h2>
#         <ul class="version-changes">
#           <li class="version-change">
#             item #1
#           </li>
#           <h3>
#             [Foo]
#           </h3>
#           <li class="version-change">
#             item #2
#           </li>
#         </ul>
#       </div>
#     </div>
#   </body>
# </html>