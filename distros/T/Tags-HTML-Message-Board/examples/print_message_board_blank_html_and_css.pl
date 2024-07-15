#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Message::Board::Blank;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'no_simple' => ['textarea'],
        'preserved' => ['style', 'textarea'],
        'xml' => 1,
);
my $obj = Tags::HTML::Message::Board::Blank->new(
        'css' => $css,
        'tags' => $tags,
);

# Process message board.
$obj->process_css;
$obj->process;

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# textarea {
#         width: 100%;
#         padding: 12px 20px;
#         margin: 8px 0;
#         display: inline-block;
#         border: 1px solid #ccc;
#         border-radius: 4px;
#         box-sizing: border-box;
# }
# button {
#         width: 100%;
#         background-color: #4CAF50;
#         color: white;
#         padding: 14px 20px;
#         margin: 8px 0;
#         border: none;
#         border-radius: 4px;
#         cursor: pointer;
# }
# button:hover {
#         background-color: #45a049;
# }
# .message-board-blank {
#         max-width: 600px;
#         margin: auto;
# }
# .message-board-blank .title {
#         margin-top: 20px;
#         font-weight: bold;
#         font-size: 1.2em;
# }
# button {
#         margin: 0;
# }
# 
# HTML
# <div class="message-board-blank">
#   <div class="title">
#     Add message board
#   </div>
#   <form method="post">
#     <textarea autofocus="autofocus" rows="6"></textarea>    <button type="button">
#       Save
#     </button>
#   </form>
# </div>