#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::Option;
use Tags::HTML::Element::Option;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Element::Option->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for option.
my $option = Data::HTML::Element::Option->new(
        'css_class' => 'form-option',
        'data' => ['Option'],
);

# Initialize.
$obj->init($option);

# Process option.
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
# <option class="form-option">
#   Option
# </option>
#
# CSS:
# TODO