#!/usr/local/bin/perl

BEGIN {  push(@INC, './t') }	# where is W.pm
use W;

print W->new()->test('test2', "examples/html_template.pl", *DATA);

__DATA__
<HTML>
<HEAD></HEAD>
<body>
<H1>First Section</H1><p>Nothing to write
<H1>Second section</H1><p>Nothing else to write

</body>
</html>
