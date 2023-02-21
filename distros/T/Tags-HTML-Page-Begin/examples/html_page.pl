#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Page::Begin;
use Tags::HTML::Page::End;
use Tags::Output::Indent;

# Object.
my $tags = Tags::Output::Indent->new(
        'preserved' => ['style'],
        'xml' => 1,
);
my $css = CSS::Struct::Output::Indent->new;
my $begin = Tags::HTML::Page::Begin->new(
        'css' => $css,
        'tags' => $tags,
);
my $end = Tags::HTML::Page::End->new(
        'tags' => $tags,
);

# Process page
$begin->process_css;
$css->put(
       ['s', 'div'],
       ['d', 'color', 'red'],
       ['d', 'background-color', 'black'],
       ['e'],
);
$begin->process;
$tags->put(
       ['b', 'div'],
       ['d', 'Hello world!'],
       ['e', 'div'],
);
$end->process;

# Print out.
print $tags->flush;

# Output like:
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#     <meta name="generator" content=
#       "Perl module: Tags::HTML::Page::Begin, Version: 0.16" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Page title
#     </title>
#     <style type="text/css">
# * {
#         box-sizing: border-box;
#         margin: 0;
#         padding: 0;
# }
# div {
#         color: red;
#         background-color: black;
# }
# </style>
#   </head>
#   <body>
#     <div>
#       Hello world!
#     </div>
#   </body>
# </html>