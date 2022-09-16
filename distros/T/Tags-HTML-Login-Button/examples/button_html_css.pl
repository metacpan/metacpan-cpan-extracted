#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Login::Button;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Login::Button->new(
        'css' => $css,
        'tags' => $tags,
);

# Process login button.
$obj->process_css;
$tags->put(['b', 'body']);
$obj->process;
$tags->put(['e', 'body']);

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# .outer {
#         position: fixed;
#         top: 50%;
#         left: 50%;
#         transform: translate(-50%, -50%);
# }
# .login {
#         text-align: center;
# }
# .login a {
#         text-decoration: none;
#         background-image: linear-gradient(to bottom,#fff 0,#e0e0e0 100%);
#         background-repeat: repeat-x;
#         border: 1px solid #adadad;
#         border-radius: 4px;
#         color: black;
#         font-family: sans-serif!important;
#         padding: 15px 40px;
# }
# .login a:hover {
#         background-color: #e0e0e0;
#         background-image: none;
# }
#
# HTML
# <body class="outer">
#   <div class="login">
#     <a href="login">
#       LOGIN
#     </a>
#   </div>
# </body>