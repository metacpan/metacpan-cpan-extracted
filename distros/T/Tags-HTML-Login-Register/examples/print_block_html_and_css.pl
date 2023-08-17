#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Login::Register;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Login::Register->new(
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
# .form-register {
# 	width: ;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-register fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-register legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-register p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-register label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-register input[type="text"], .form-register input[type="password"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-register button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-register button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# 
# HTML
# <form class="form-register" method="post">
#   <fieldset>
#     <legend>
#       Register
#     </legend>
#     <p>
#       <label for="username">
#       </label>
#       User name
#       <input type="text" name="username" id="username" autofocus="autofocus">
#       </input>
#     </p>
#     <p>
#       <label for="password1">
#         Password #1
#       </label>
#       <input type="password" name="password1" id="password1">
#       </input>
#     </p>
#     <p>
#       <label for="password2">
#         Password #2
#       </label>
#       <input type="password" name="password2" id="password2">
#       </input>
#     </p>
#     <p>
#       <button type="submit" name="register" value="register">
#         Register
#       </button>
#     </p>
#   </fieldset>
# </form>