#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Login::Access;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Login::Access->new(
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
# .form-login {
# 	width: 300px;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-login fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-login legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-login p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-login label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-login input[type="text"], .form-login input[type="password"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-login button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-login button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# 
# HTML
# <form class="form-login" method="post">
#   <fieldset>
#     <legend>
#       Login
#     </legend>
#     <p>
#       <label for="username">
#       </label>
#       User name
#       <input type="text" name="username" id="username" autofocus="autofocus">
#       </input>
#     </p>
#     <p>
#       <label for="password">
#         Password
#       </label>
#       <input type="password" name="password" id="password">
#       </input>
#     </p>
#     <p>
#       <button type="submit" name="login" value="login">
#         Login
#       </button>
#     </p>
#   </fieldset>
# </form>