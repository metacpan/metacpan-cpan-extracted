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
# .table, .table td, .table th {
#         border: 1px solid #ddd;
#         text-align: left;
# }
# .table {
#         border-collapse: collapse;
#         width: 100%;
# }
# .table th, .table td {
#         padding: 15px;
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
#       <td colspan="2">
#         No data.
#       </td>
#     </tr>
#   </table>
# </body>