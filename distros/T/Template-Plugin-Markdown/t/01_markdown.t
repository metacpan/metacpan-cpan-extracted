use strict;
use Test::More tests => 2;
use Template;

my $tt = Template->new;

$tt->process(\<<EOF, {}, \my $html1) or die $tt->error;
[% USE Markdown -%]
[% FILTER markdown -%]
Foo

Bar
[%- END -%]
EOF

is(<<"EOF", $html1);
<p>Foo</p>

<p>Bar</p>
EOF

$tt->process(\<<EOF, {}, \my $html2) or die $tt->error;
[% USE Markdown -%]
[% FILTER markdown -%]
#Foo
Bar
---
*Italic*

**Bold**
[%- END -%]
EOF

is( <<"EOF", $html2 );
<h1>Foo</h1>

<h2>Bar</h2>

<p><em>Italic</em></p>

<p><strong>Bold</strong></p>
EOF

