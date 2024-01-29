#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::HTML::Element::A;
use Tags::HTML::Element::A;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Element::A->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for a.
my $a = Data::HTML::Element::A->new(
        'css_class' => 'a',
        'data' => ['Link'],
        'url' => 'http://example.com',
);

# Initialize.
$obj->init($a);

# Process a.
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
# <a class="a" href="http://example.com">
#   Link
# </a>
#
# CSS:
# - no CSS now.