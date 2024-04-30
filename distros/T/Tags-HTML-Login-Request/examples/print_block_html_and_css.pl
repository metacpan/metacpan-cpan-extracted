#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Login::Request;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Login::Request->new(
        'css' => $css,
        'tags' => $tags,
);

# Process login button.
$obj->process_css;
$obj->process;

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# .form-request {
#         width: 300px;
#         background-color: #f2f2f2;
#         padding: 20px;
#         border-radius: 5px;
#         box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-request .logo {
#         height: 5em;
#         width: 100%;
# }
# .form-request img {
#         margin: auto;
#         display: block;
#         max-width: 100%;
#         max-height: 5em;
# }
# .form-request fieldset {
#         border: none;
#         padding: 0;
#         margin-bottom: 20px;
# }
# .form-request legend {
#         font-weight: bold;
#         margin-bottom: 10px;
# }
# .form-request p {
#         margin: 0;
#         padding: 10px 0;
# }
# .form-request label {
#         display: block;
#         font-weight: bold;
#         margin-bottom: 5px;
# }
# .form-request input[type="email"] {
#         width: 100%;
#         padding: 8px;
#         border: 1px solid #ccc;
#         border-radius: 3px;
# }
# .form-request button[type="submit"] {
#         width: 100%;
#         padding: 10px;
#         background-color: #4CAF50;
#         color: #fff;
#         border: none;
#         border-radius: 3px;
#         cursor: pointer;
# }
# .form-request button[type="submit"]:hover {
#         background-color: #45a049;
# }
# .form-request .messages {
#         text-align: center;
# }
# 
# HTML
# <form class="form-request" method="post">
#   <fieldset>
#     <legend>
#       Login request
#     </legend>
#     <p>
#       <label for="email">
#       </label>
#       Email
#       <input type="email" name="email" id="email" autofocus="autofocus">
#       </input>
#     </p>
#     <p>
#       <button type="submit" name="login_request" value="login_request">
#         Request
#       </button>
#     </p>
#   </fieldset>
# </form>