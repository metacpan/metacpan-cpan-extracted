#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::DefinitionList;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::DefinitionList->new(
        'css' => $css,
        'tags' => $tags,
);

$obj->init([
        ['cze' => 'Czech'],
        ['eng' => 'English'],
]);

# Process container with text.
$obj->process;
$obj->process_css;

# Print out.
print $tags->flush;
print "\n\n";
print $css->flush;

# Output:
# <dl class="dl">
#   <dt>
#     cze
#   </dt>
#   <dd>
#     Czech
#   </dd>
#   <dt>
#     eng
#   </dt>
#   <dd>
#     English
#   </dd>
# </dl>
# 
# .dl {
#         padding: 0.5em;
# }
# .dl dt {
#         float: left;
#         clear: left;
#         width: 100px;
#         text-align: right;
#         font-weight: bold;
#         color: black;
# }
# .dl dt:after {
#         content: ":";
# }
# .dl dd {
#         margin: 0 0 0 110px;
#         padding: 0 0 0.5em 0;
# }