#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Element::Form;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Element::Form->new(
        'css' => $css,
        'tags' => $tags,
);

# Process form.
$obj->process;
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# <form class="form" method="GET">
#   <p>
#     <button type="submit">
#       Save
#     </button>
#   </p>
# </form>
# 
# .form {
#         border-radius: 5px;
#         background-color: #f2f2f2;
#         padding: 20px;
# }
# .form input[type=submit]:hover {
#         background-color: #45a049;
# }
# .form input[type=submit] {
#         width: 100%;
#         background-color: #4CAF50;
#         color: white;
#         padding: 14px 20px;
#         margin: 8px 0;
#         border: none;
#         border-radius: 4px;
#         cursor: pointer;
# }
# .form input, select, textarea {
#         width: 100%;
#         padding: 12px 20px;
#         margin: 8px 0;
#         display: inline-block;
#         border: 1px solid #ccc;
#         border-radius: 4px;
#         box-sizing: border-box;
# }
# .form-required {
#         color: red;
# }