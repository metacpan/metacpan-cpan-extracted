#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Data::Icon;
use Tags::HTML::Icon;
use Tags::Output::Indent;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::Icon->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for icon.
my $icon = Data::Icon->new(
        'bg_color' => 'grey',
        'char' => decode_utf8('†'),
        'color' => 'red',
);

# Initialize.
$obj->init($icon);

# Process.
$obj->process;
$obj->process_css;

# Print out.
print "HTML:\n";
print encode_utf8($tags->flush);
print "\n\n";
print "CSS:\n";
print $css->flush;

# Output:
# HTML:
# <span class="icon">
#   <span style="background-color:grey;color:red;">
#     †
#   </span>
# </span>
# 
# CSS:
# 