#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;
use Tags::HTML::Table::View;
use Tags::Output::Indent;

# Object.
my $css = CSS::Struct::Output::Indent->new;
my $tags = Tags::Output::Indent->new;
my $obj = Tags::HTML::Table::View->new(
        'css' => $css,
        'tags' => $tags,
);

# Table data.
my $table_data_ar = [
        ['Country', 'Capital'],
        ['Czech Republic', 'Prague'],
        ['Russia', 'Moscow'],
];

# Process login button.
$obj->init($table_data_ar, 'No data.');
$obj->process_css;
$tags->put(['b', 'body']);
$obj->process;
$tags->put(['e', 'body']);
$obj->cleanup;

# Print out.
print "CSS\n";
print $css->flush."\n\n";
print "HTML\n";
print $tags->flush."\n";

# Output:
# CSS
# .table table, .table th, .table td {
#         border: 1px solid black;
# }
#
# HTML
# <body>
#   <table class="table">
#     <tr>
#       <th>
#         Country
#       </th>
#       <th>
#         Capital
#       </th>
#     </tr>
#     <tr>
#       <td>
#         Czech Republic
#       </td>
#       <td>
#         Prague
#       </td>
#     </tr>
#     <tr>
#       <td>
#         Russia
#       </td>
#       <td>
#         Moscow
#       </td>
#     </tr>
#   </table>
# </body>