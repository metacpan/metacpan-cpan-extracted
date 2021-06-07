#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::GradientIndicator;
use Tags::Output::Indent;

if (@ARGV < 1) {
        print STDERR "Usage: $0 percent\n";
        exit 1;
}
my $percent = $ARGV[0];

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::GradientIndicator->new(
        'css' => $css,
        'tags' => $tags,
);

# Process indicator.
$obj->process_css;
$obj->process($percent);

# Print out.
print "CSS\n";
print $css->flush."\n";
print "HTML\n";
print $tags->flush."\n";

# Output for 30:
# CSS
# .gradient {
#         height: 30px;
#         width: 500px;
#         background-color: red;
#         background-image: linear-gradient(to right, red, orange, yellow, green, blue, indigo, violet);
# }
# HTML
# <div style="width: 150px;overflow: hidden;">
#   <div class="gradient">
#   </div>
# </div>