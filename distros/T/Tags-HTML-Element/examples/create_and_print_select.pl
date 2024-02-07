#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Select;
use Tags::HTML::Element::Select;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Element::Select->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for select.
my $select = Data::HTML::Element::Select->new(
        'css_class' => 'form-select',
);

# Initialize.
$obj->init($select);

# Process select.
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
# <select class="form-select" />
#
# CSS:
# select.form-select {
#         width: 100%;
#         padding: 12px 20px;
#         margin: 8px 0;
#         display: inline-block;
#         border: 1px solid #ccc;
#         border-radius: 4px;
#         box-sizing: border-box;
# }