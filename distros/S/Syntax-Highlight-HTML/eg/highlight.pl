#!/usr/bin/perl
use strict;
use Syntax::Highlight::HTML;

my $content = '';
my $file = shift;
open(FILE, '<'.$file) or die "can't read '$file': $!";
{ local $/ = undef;
  $content = <FILE>;
}

my $highlighter = new Syntax::Highlight::HTML nnn => 1;
print <<'HEAD', $highlighter->parse($content), <<'BOTTOM';
<html>
<head>
<title>Syntax::Highlight::HTML</title>
<link rel="stylesheet" type="text/css" href="eg/html-syntax.css" />
</head>
<body>
HEAD
</body>
</html>
BOTTOM

