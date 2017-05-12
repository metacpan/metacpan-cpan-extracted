#!/usr/bin/perl -w

# t/table.t - check the output of tables to html

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 9;

use_ok('Pod::PseudoPod::HTML') or exit;

my $parser = Pod::PseudoPod::HTML->new ();
isa_ok ($parser, 'Pod::PseudoPod::HTML');

my $results;

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table

=row

=cell Cell 1

=cell Cell 2

=end table

EOPOD

is($results, <<'EOHTML', "a simple table");
<table>

<tr>

<td>Cell 1</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table An Example Table

=row

=cell Cell 1

=cell Cell 2

=end table

EOPOD

is($results, <<'EOHTML', "a table with a title");
<i>Table: An Example Table</i>
<table>

<tr>

<td>Cell 1</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table

=headrow

=row

=cell Header 1

=cell Header 2

=bodyrows

=row

=cell Cell 1

=cell Cell 2

=end table

EOPOD

is($results, <<'EOHTML', "a table with a header row");
<table>

<tr>

<th>Header 1</th>

<th>Header 2</th>

</tr>

<tr>

<td>Cell 1</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

TODO: {
local $TODO = "add checks for empty rows";
initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table

=row

=end table

EOPOD

is($results, <<'EOHTML', "a table with an empty row");
<table>

</table>

EOHTML
}; # TODO

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table picture An Example Table

=row

=cell Cell 1

=cell Cell 2

=end table

EOPOD

is($results, <<'EOHTML', "get rid of table type info");
<i>Table: An Example Table</i>
<table>

<tr>

<td>Cell 1</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table

Z<table1>

=row

=cell Cell 1

=cell Cell 2

=end table

EOPOD

is($results, <<'EOHTML', "a table with a Z<> tag inside");
<table>

<p><a name="table1"></p>

<tr>

<td>Cell 1</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

initialize($parser, $results);
$parser->parse_string_document(<<'EOPOD');
=begin table

=row

=cell This is a really, really long cell. So long, in fact that it
wraps right around.

=cell Cell 2

=end table

EOPOD
is($results, <<'EOHTML', "lines in cells are not wrapped");
<table>

<tr>

<td>This is a really, really long cell. So long, in fact that it wraps right around.</td>

<td>Cell 2</td>

</tr>

</table>

EOHTML

######################################

sub initialize {
	$_[0] = Pod::PseudoPod::HTML->new ();
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}
