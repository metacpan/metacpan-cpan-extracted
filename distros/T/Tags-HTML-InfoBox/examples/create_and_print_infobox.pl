#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::InfoBox;
use Tags::Output::Indent;
use Test::Shared::Fixture::Data::InfoBox::Street;
use Unicode::UTF8 qw(encode_utf8);

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new(
        'xml' => 1,
);
my $obj = Tags::HTML::InfoBox->new(
        'css' => $css,
        'tags' => $tags,
);

# Data object for info box.
my $infobox = Test::Shared::Fixture::Data::InfoBox::Street->new;

# Initialize.
$obj->init($infobox);

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
# <table class="info-box">
#   <tr>
#     <td />
#     <td>
#       Nábřeží Rudoarmějců
#     </td>
#   </tr>
#   <tr>
#     <td />
#     <td>
#       Příbor
#     </td>
#   </tr>
#   <tr>
#     <td />
#     <td>
#       Česká republika
#     </td>
#   </tr>
# </table>
# 
# CSS:
# .info-box {
#         background-color: #32a4a8;
#         padding: 1em;
# }
# .info-box .icon {
#         text-align: center;
# }
# .info-box a {
#         text-decoration: none;
# }