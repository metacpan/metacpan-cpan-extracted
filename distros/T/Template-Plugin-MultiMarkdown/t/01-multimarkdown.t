#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 5;
use Template;
use FindBin qw($Bin);
use lib "$Bin/../lib";

my $tt = Template->new;

##############################################################################

$tt->process(\<<EOF, {}, \my $html1) or die $tt->error;
[% USE MultiMarkdown -%]
[% FILTER multimarkdown -%]
Foo

Bar
[%- END -%]
EOF
chomp($html1);

my $html1e = <<EOF;
<p>Foo</p>

<p>Bar</p>
EOF
chomp($html1e);

is($html1, $html1e);

##############################################################################

$tt->process(\<<EOF, {}, \my $html2) or die $tt->error;
[% USE MultiMarkdown(implementation = 'PP') -%]
[% FILTER multimarkdown(heading_ids = 0) -%]
#Foo

Bar
---
*Italic*

**Bold**
[%- END -%]
EOF

my $html2e = <<EOF;
<h1>Foo</h1>

<h2>Bar</h2>

<p><em>Italic</em></p>

<p><strong>Bold</strong></p>
EOF

chomp($html2);
chomp($html2e);

is( $html2, $html2e );

##############################################################################

$tt->process(\<<EOF, {}, \my $html3) or die $tt->error;
[% USE MultiMarkdown -%]
[% FILTER multimarkdown(heading_ids = 1, implementation = 'PP') -%]
#Foo

Bar
---
*Italic*

**Bold**
[%- END -%]
EOF

is( <<"EOF", $html3 );
<h1 id="foo">Foo</h1>

<h2 id="bar">Bar</h2>

<p><em>Italic</em></p>

<p><strong>Bold</strong></p>
EOF

$tt->process(\<<EOF, {}, \my $html4) or die $tt->error;
[% USE MultiMarkdown -%]
[% FILTER multimarkdown(heading_ids = 1, implementation = 'PP') -%]

|      | Spanned Column |
| Col1 | col2  | col3   |
|------|-------|--------|
| A    |    42 |   42   |
| B    |     x |    y   |
[sample table]

[%- END -%]
EOF

is( $html4, <<"EOF" );
<table>
<caption>sample table</caption>
<col />
<col />
<col />
<thead>
<tr>
	<th> </th>
	<th>Spanned Column</th>
</tr>
<tr>
	<th>Col1</th>
	<th>col2</th>
	<th>col3</th>
</tr>
</thead>
<tbody>
<tr>
	<td>A</td>
	<td>42</td>
	<td>42</td>
</tr>
<tr>
	<td>B</td>
	<td>x</td>
	<td>y</td>
</tr>
</tbody>
</table>
EOF


$tt->process(\<<EOF, {}, \my $html5) or die $tt->error;
[% USE MultiMarkdown -%]
[% FILTER multimarkdown(heading_ids = 1, implementation = 'PP') -%]

This is an image ![An image][img]

[img]: image.jpg "some image" height=50 width=50 align=left

[%- END -%]
EOF

is( $html5, <<"EOF" );
<p>This is an image <img src="image.jpg" alt="An image" title="some image" id="animage" height="50" width="50" align="left" /></p>
EOF

