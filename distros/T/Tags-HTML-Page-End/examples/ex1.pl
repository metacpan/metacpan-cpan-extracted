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
$begin->process;
$tags->put(
       ['b', 'div'],
       ['d', 'Hello world!'],
       ['e', 'div'],
);
$end->process;

# Print out.
print $tags->flush;

# Output:
# <!DOCTYPE html>
# <html>
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
#     </meta>
#     <title>
#       Page title
#     </title>
#     <style type="text/css">
# .okay {
# 	background: #9f9;
# }
# .warning {
# 	background: #ff9;
# }
# .alert {
# 	background: #f99;
# }
# .offline {
# 	color: #999;
# }
# </style>
#   </head>
#   <body>
#     <div>
#       Hello world!
#     </div>
#   </body>
# </html>