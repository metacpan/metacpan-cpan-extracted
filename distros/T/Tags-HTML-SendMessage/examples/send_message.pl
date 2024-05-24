#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Page::Begin;
use Tags::HTML::Page::End;
use Tags::HTML::SendMessage;
use Tags::Output::Indent;

# Object.
my $tags = Tags::Output::Indent->new(
        'preserved' => ['style'],
        'xml' => 1,
        'no_simple' => ['textarea'],
);
my $begin = Tags::HTML::Page::Begin->new(
        'generator' => 'Tags::HTML::SendMessage EXAMPLE1',
        'tags' => $tags,
);
my $send_message = Tags::HTML::SendMessage->new(
        'tags' => $tags,
);
my $end = Tags::HTML::Page::End->new(
        'tags' => $tags,
);

# Process page
$begin->process;
$send_message->process;
$end->process;

# Print out.
print $tags->flush;

# Output:
# <!DOCTYPE html>
# <html lang="en">
#   <head>
#     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
#     <meta name="generator" content="Tags::HTML::SendMessage EXAMPLE1" />
#     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
#     <title>
#       Page title
#     </title>
#   </head>
#   <body>
#     <div id="send-message">
#       <form action="">
#         <fieldset>
#           <legend>
#             Leave us a message
#           </legend>
#           <label for="name-and-surname">
#             Name and surname:
#           </label>
#           <br />
#           <input id="name-and-surname" name="name-and-surname" size="30" />
#           <br />
#           <label for="email">
#             Email:
#           </label>
#           <br />
#           <input id="email" name="email" size="30" />
#           <br />
#           <label for="subject">
#             Subject of you question:
#           </label>
#           <br />
#           <input id="subject" name="subject" size="72" />
#           <br />
#           <label for="your-message">
#             Your message:
#           </label>
#           <br />
#           <textarea id="your-message" name="your-message" cols="75" rows="10">
#           </textarea>
#           <br />
#           <input type="submit" value="Send question" />
#         </fieldset>
#       </form>
#     </div>
#   </body>
# </html>