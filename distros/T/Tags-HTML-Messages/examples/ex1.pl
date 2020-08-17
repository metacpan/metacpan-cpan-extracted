#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Page::Begin;
use Tags::HTML::Page::End;
use Tags::HTML::Messages;
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
my $messages = Tags::HTML::Messages->new(
        'css' => $css,
        'tags' => $tags,
);

# Error structure.
my $error_messages_ar = [
        'Error #1',
        'Error #2',
];
my $ok_messages_ar = [
        'Ok #1',
        'Ok #2',
];

# Process page.
$messages->process_css('error', 'red');
$messages->process_css('ok', 'green');
$begin->process;
$messages->process($error_messages_ar, 'error');
$messages->process($ok_messages_ar, 'ok');
$end->process;

# Print out.
print $tags->flush;

# Output:
# <!DOCTYPE html>
# <html>
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#     <title>
#       Page title
#     </title>
#     <style type="text/css">
# #error {
# 	color: red;
# }
# #ok {
# 	color: green;
# }
# </style>
#   </head>
#   <body>
#     <span id="error">
#       Error #1
#     </span>
#     <span id="error">
#       Error #2
#     </span>
#     <span id="ok">
#       Ok #1
#     </span>
#     <span id="ok">
#       Ok #2
#     </span>
#   </body>
# </html>