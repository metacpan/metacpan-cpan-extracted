#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test('test5', "examples/html_generator.pl", *DATA);

__DATA__
<HTML>
<HEAD>
</HEAD>

<BODY>
<p>A very simple document: 
<OL><li>0
<OL><li>1
<OL><li>2
<OL><li>3<li>3
</OL>
<li>2
</OL>
<li>1
</OL>
<li>0
</OL>

</BODY>
</HTML>
<H1><b>text in bold</b><i>text in italic</i></H1>
<H1><B>text in bold</B><I>text in italic</I></H1>
<H1><B>text in bold</B><I>text in italic</I></H1>
<H1><B>text in bold</B><I>text in italic</I></H1>

