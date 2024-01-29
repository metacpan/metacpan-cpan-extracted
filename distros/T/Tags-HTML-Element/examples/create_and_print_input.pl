#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Input;
use Tags::HTML::Element::Input;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Element::Input->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for input.
my $input = Data::HTML::Element::Input->new(
        'css_class' => 'form-input',
);

# Initialize.
$obj->init($input);

# Process input.
$obj->process;
$obj->process_css;

# Print out.
print "HTML:\n";
print $tags->flush;
print "\n\n";
print "CSS:\n";
print $css->flush;

# Output:
# HTML:
# <input class="form-input" type="text" />
#
# CSS:
# input.form-input[type=submit]:hover {
#         background-color: #45a049;
# }
# input.form-input[type=submit] {
#         width: 100%;
#         background-color: #4CAF50;
#         color: white;
#         padding: 14px 20px;
#         margin: 8px 0;
#         border: none;
#         border-radius: 4px;
#         cursor: pointer;
# }
# input.form-input {
#         width: 100%;
#         padding: 12px 20px;
#         margin: 8px 0;
#         display: inline-block;
#         border: 1px solid #ccc;
#         border-radius: 4px;
#         box-sizing: border-box;
# }