#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Button;
use Tags::HTML::Element::Button;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Element::Button->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for button.
my $button = Data::HTML::Element::Button->new(
        'css_class' => 'button',
);

# Initialize.
$obj->init($button);

# Process button.
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
# <button type="button" class="button" />
#
# CSS:
# button.button {
#         width: 100%;
#         background-color: #4CAF50;
#         color: white;
#         padding: 14px 20px;
#         margin: 8px 0;
#         border: none;
#         border-radius: 4px;
#         cursor: pointer;
# }
# button.button:hover {
#         background-color: #45a049;
# }