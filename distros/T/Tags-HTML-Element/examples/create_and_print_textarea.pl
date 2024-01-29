#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Textarea;
use Tags::HTML::Element::Textarea;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'no_simple' => ['textarea'],
        'preserved' => ['textarea'],
        'xml' => 1,
);
my $obj = Tags::HTML::Element::Textarea->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for textarea.
my $textarea = Data::HTML::Element::Textarea->new(
        'cols' => 5,
        'css_class' => 'textarea',
        'id' => 'textarea',
        'rows' => 10,
);

# Initialize.
$obj->init($textarea);

# Process textarea.
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
# <textarea class="textarea" id="textarea" cols="5" rows="10"></textarea>
#
# CSS:
# textarea.textarea {
#         width: 100%;
#         padding: 12px 20px;
#         margin: 8px 0;
#         display: inline-block;
#         border: 1px solid #ccc;
#         border-radius: 4px;
#         box-sizing: border-box;
# }