#!/usr/bin/env perl

use Test::More tests => 4;

use Syntax::Highlight::CSS;

can_ok('Syntax::Highlight::CSS', qw/new parse/);
my $p = Syntax::Highlight::CSS->new;

isa_ok($p,'Syntax::Highlight::CSS');

my $CSS =<<'END';
@charset 'UTF-8';
@import 'bar.css';
* { margin: 0; padding: 0; }
@media screen {
    a:hover { font-weight: bold; }
}
/* just an example */
END

my $out = $p->parse($CSS);

my $VAR1 = "<pre class=\"css-code\"><span class=\"ch-at\">\@charset 'UTF-8'</span>;\n<span class=\"ch-at\">\@import 'bar.css'</span>;\n<span class=\"ch-sel\">*</span> { <span class=\"ch-p\">margin</span>: <span class=\"ch-v\">0</span>; <span class=\"ch-p\">padding</span>: <span class=\"ch-v\">0</span>; }\n<span class=\"ch-at\">\@media screen</span> {\n    <span class=\"ch-sel\">a<span class=\"ch-ps\">:hover</span></span> { <span class=\"ch-p\">font-weight</span>: <span class=\"ch-v\">bold</span>; }\n}\n<span class=\"ch-com\">/* just an example */</span>\n</pre>";

is($out, $VAR1, 'parse matches expectations');

$p = Syntax::Highlight::CSS->new( nnn => 1 );
$out = $p->parse($CSS);

$VAR1 = "<pre class=\"css-code\"><span class=\"ch-l\">  0</span> <span class=\"ch-at\">\@charset 'UTF-8'</span>;\n<span class=\"ch-l\">  1</span> <span class=\"ch-at\">\@import 'bar.css'</span>;\n<span class=\"ch-l\">  2</span> <span class=\"ch-sel\">*</span> { <span class=\"ch-p\">margin</span>: <span class=\"ch-v\">0</span>; <span class=\"ch-p\">padding</span>: <span class=\"ch-v\">0</span>; }\n<span class=\"ch-l\">  3</span> <span class=\"ch-at\">\@media screen</span> {\n<span class=\"ch-l\">  4</span>     <span class=\"ch-sel\">a<span class=\"ch-ps\">:hover</span></span> { <span class=\"ch-p\">font-weight</span>: <span class=\"ch-v\">bold</span>; }\n<span class=\"ch-l\">  5</span> }\n<span class=\"ch-l\">  6</span> <span class=\"ch-com\">/* just an example */</span>\n</pre>";

is($out,$VAR1, 'parse matches expectations when lines numbers are on');
