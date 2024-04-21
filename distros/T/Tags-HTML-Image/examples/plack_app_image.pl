#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::Image;
use DateTime;
use Plack::App::Tags::HTML;
use Plack::Runner;
use Tags::Output::Indent;

my $image = Data::Image->new(
	'author' => 'Zuzana Zonova',
	'comment' => 'Michal from Czechia',
	'dt_created' => DateTime->new(
		'day' => 1,
		'month' => 1,
		'year' => 2022,
	),
	'height' => 2730,
	'size' => 1040304,
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
	'width' => 4096,
);

my $app = Plack::App::Tags::HTML->new(
	'component' => 'Tags::HTML::Image',
	'css' => CSS::Struct::Output::Indent->new,
	'data_init' => [$image],
	'tags' => Tags::Output::Indent->new(
		'xml' => 1,
		'preserved' => ['style'],
	),
	'title' => 'Image',
)->to_app;
Plack::Runner->new->run($app);

# Output (GET /):
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Image
#     </title>
#     <style type="text/css">
# * {
#         box-sizing: border-box;
#         margin: 0;
#         padding: 0;
# }
# .image img {
#         display: block;
#         height: 100%;
#         width: 100%;
#         object-fit: contain;
# }
# .image {
#         height: calc(100vh);
# }
# .image figcaption {
#         position: absolute;
#         bottom: 0;
#         background: rgb(0, 0, 0);
#         background: rgba(0, 0, 0, 0.5);
#         color: #f1f1f1;
#         width: 100%;
#         transition: .5s ease;
#         opacity: 0;
#         font-size: 25px;
#         padding: 12.5px 5px;
#         text-align: center;
# }
# figure.image:hover figcaption {
#         opacity: 1;
# }
# </style>
#   </head>
#   <body>
#     <figure class="image">
#       <img alt="Michal from Czechia" src=
#         "https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg"
#         />
#       <figcaption>
#         Michal from Czechia
#       </figcaption>
#     </figure>
#   </body>
# </html>