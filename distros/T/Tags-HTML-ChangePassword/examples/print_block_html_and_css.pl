#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::ChangePassword;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::ChangePassword->new(
        'css' => $css,
        'tags' => $tags,
);

# Process change password form.
$obj->process_css;
$obj->process;

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# .form-change-password {
# 	width: 300px;
# 	background-color: #f2f2f2;
# 	padding: 20px;
# 	border-radius: 5px;
# 	box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
# }
# .form-change-password fieldset {
# 	border: none;
# 	padding: 0;
# 	margin-bottom: 20px;
# }
# .form-change-password legend {
# 	font-weight: bold;
# 	margin-bottom: 10px;
# }
# .form-change-password p {
# 	margin: 0;
# 	padding: 10px 0;
# }
# .form-change-password label {
# 	display: block;
# 	font-weight: bold;
# 	margin-bottom: 5px;
# }
# .form-change-password input[type="text"], .form-change-password input[type="password"] {
# 	width: 100%;
# 	padding: 8px;
# 	border: 1px solid #ccc;
# 	border-radius: 3px;
# }
# .form-change-password button[type="submit"] {
# 	width: 100%;
# 	padding: 10px;
# 	background-color: #4CAF50;
# 	color: #fff;
# 	border: none;
# 	border-radius: 3px;
# 	cursor: pointer;
# }
# .form-change-password button[type="submit"]:hover {
# 	background-color: #45a049;
# }
# .form-change-password .messages {
# 	text-align: center;
# }
# 
# HTML
# <form class="form-change-password" method="post">
#   <fieldset>
#     <legend>
#       Change password
#     </legend>
#     <p>
#       <label for="old_password">
#         Old password
#       </label>
#       <input type="password" name="old_password" id="old_password" autofocus=
#         "autofocus">
#       </input>
#     </p>
#     <p>
#       <label for="password1">
#         New password
#       </label>
#       <input type="password" name="password1" id="password1">
#       </input>
#     </p>
#     <p>
#       <label for="password2">
#         Confirm new password
#       </label>
#       <input type="password" name="password2" id="password2">
#       </input>
#     </p>
#     <p>
#       <button type="submit" name="change_password" value="change_password">
#         Save Changes
#       </button>
#     </p>
#   </fieldset>
# </form>