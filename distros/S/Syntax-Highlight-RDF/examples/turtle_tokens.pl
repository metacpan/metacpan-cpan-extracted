use v5.10;
use strict;
use warnings;

use Syntax::Highlight::RDF;

my $data = do { local $/ = <DATA> };
my $hl   = "Syntax::Highlight::RDF"->highlighter("Turtle");

$hl->tokenize(\$data);
$hl->_fixup("xyzzy/");

for my $tok (@{$hl->_tokens})
{
	say $tok->tok;
}

__DATA__
@prefix foo: <http://example.com/foo#> .
@prefix quux: <quux#>.

<xyz>
   foo:foo <\U00000061bc>
   foo:bar 123;
   foo:baz "Yeah\"Baby\"Yeah";
   foo:bum quux:quuux.

