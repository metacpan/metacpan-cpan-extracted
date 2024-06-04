#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Message::Board;
use Tags::Output::Indent;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'no_simple' => ['textarea'],
        'preserved' => ['style', 'textarea'],
        'xml' => 1,
);
my $obj = Tags::HTML::Message::Board->new(
        'css' => $css,
        'tags' => $tags,
);

# Init.
my $board = Test::Shared::Fixture::Data::Message::Board::Example->new;
$obj->init($board);

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
# .message-board .main-message {
# 	border: 1px solid #ccc;
# 	padding: 20px;
# 	border-radius: 5px;
# 	background-color: #f9f9f9;
# 	max-width: 600px;
# 	margin: auto;
# }
# .message-board .comments {
# 	max-width: 600px;
# 	margin: auto;
# }
# .message-board .comment {
# 	border-left: 2px solid #ccc;
# 	padding-left: 10px;
# 	margin-top: 20px;
# 	margin-left: 10px;
# }
# .author {
# 	font-weight: bold;
# 	font-size: 1.2em;
# }
# .comment .author {
# 	font-size: 1em;
# }
# .date {
# 	color: #555;
# 	font-size: 0.9em;
# 	margin-bottom: 10px;
# }
# .comment .date {
# 	font-size: 0.8em;
# }
# .text {
# 	margin-top: 10px;
# }
# textarea {
# 	width: 100%;
# 	padding: 12px 20px;
# 	margin: 8px 0;
# 	display: inline-block;
# 	border: 1px solid #ccc;
# 	border-radius: 4px;
# 	box-sizing: border-box;
# }
# button {
# 	width: 100%;
# 	background-color: #4CAF50;
# 	color: white;
# 	padding: 14px 20px;
# 	margin: 8px 0;
# 	border: none;
# 	border-radius: 4px;
# 	cursor: pointer;
# }
# button:hover {
# 	background-color: #45a049;
# }
# .message-board .add-comment {
# 	max-width: 600px;
# 	margin: auto;
# }
# .message-board .add-comment .title {
# 	margin-top: 20px;
# 	font-weight: bold;
# 	font-size: 1.2em;
# }
# button {
# 	margin: 0;
# }
# 
# HTML
# <div class="message-board">
#   <div class="main-message">
#     <div class="author">
#       Author: John Wick
#     </div>
#     <div class="date">
#       Date: 25.05.2024 17:53:20
#     </div>
#     <div class="text">
#       How to install Perl?
#     </div>
#   </div>
#   <div class="comments">
#     <div class="comment">
#       <div class="author">
#         Author: Gregor Herrmann
#       </div>
#       <div class="date">
#         Date: 25.05.2024 17:53:27
#       </div>
#       <div class="text">
#         apt-get update; apt-get install perl;
#       </div>
#     </div>
#     <div class="comment">
#       <div class="author">
#         Author: Emmanuel Seyman
#       </div>
#       <div class="date">
#         Date: 25.05.2024 17:53:37
#       </div>
#       <div class="text">
#         dnf update; dnf install perl-intepreter;
#       </div>
#     </div>
#   </div>
#   <div class="add-comment">
#     <div class="title">
#       Add comment
#     </div>
#     <form method="post">
#       <textarea autofocus="autofocus" rows="6"></textarea>      <button type="button">
#         Save
#       </button>
#     </form>
#   </div>
# </div>