use strict;
use warnings;
use Test::More;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# === \K (keep, reset match start) ===

ok( $r->regex('foo\Kbar'), '\K parses successfully' );
is( $r->visual, 'foo\Kbar', '\K visual output' );

# \K should produce a keep object
{
  $r->regex('a\Kb');
  $r->parse;
  my @nodes = @{ $r->root };
  # nodes: exact("a"), keep, exact("b")
  my $keep = $nodes[1];
  is( $keep->family, 'anchor', '\K family is anchor' );
  is( $keep->type, 'keep', '\K type is keep' );
  ok( $keep->{zerolen}, '\K is zero-length' );
}

# === \R (generic linebreak) ===

ok( $r->regex('\R'), '\R parses successfully' );
is( $r->visual, '\R', '\R visual output' );

ok( $r->regex('foo\Rbar'), '\R in context' );
is( $r->visual, 'foo\Rbar', '\R in context visual' );

{
  $r->regex('\R');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'lnbreak', '\R family is lnbreak' );
  is( $nodes[0]->type, 'lnbreak', '\R type is lnbreak' );
}

# === \h and \H (horizontal whitespace) ===

ok( $r->regex('\h'), '\h parses successfully' );
is( $r->visual, '\h', '\h visual output' );

ok( $r->regex('\H'), '\H parses successfully' );
is( $r->visual, '\H', '\H visual output' );

{
  $r->regex('\h');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'hspace', '\h family' );
  is( $nodes[0]->type, 'hspace', '\h type' );
  ok( !$nodes[0]->neg, '\h is not negated' );
}

{
  $r->regex('\H');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'hspace', '\H family' );
  is( $nodes[0]->type, 'nhspace', '\H type' );
  ok( $nodes[0]->neg, '\H is negated' );
}

# \h inside character class
ok( $r->regex('[\h]'), '\h in character class' );
is( $r->visual, '[\h]', '\h in character class visual' );

ok( $r->regex('[\H]'), '\H in character class' );
is( $r->visual, '[\H]', '\H in character class visual' );

# === \v and \V (vertical whitespace) ===

ok( $r->regex('\v'), '\v parses successfully' );
is( $r->visual, '\v', '\v visual output' );

ok( $r->regex('\V'), '\V parses successfully' );
is( $r->visual, '\V', '\V visual output' );

{
  $r->regex('\v');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'vspace', '\v family' );
  is( $nodes[0]->type, 'vspace', '\v type' );
  ok( !$nodes[0]->neg, '\v is not negated' );
}

{
  $r->regex('\V');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'vspace', '\V family' );
  is( $nodes[0]->type, 'nvspace', '\V type' );
  ok( $nodes[0]->neg, '\V is negated' );
}

# \v inside character class
ok( $r->regex('[\v]'), '\v in character class' );
is( $r->visual, '[\v]', '\v in character class visual' );

# === Named capture groups (?<name>...) ===

ok( $r->regex('(?<foo>bar)'), '(?<name>...) parses' );
is( $r->visual, '(?<foo>bar)', '(?<name>...) visual' );

{
  $r->regex('(?<test>abc)');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'open', 'named capture family is open' );
  is( $nodes[0]->name, 'test', 'named capture name' );
  is( $nodes[0]->nparen, 1, 'named capture nparen' );
  is( $r->nparen, 1, 'nparen count with named capture' );
}

# named capture with underscore and digits
ok( $r->regex('(?<foo_123>x)'), 'named capture with underscore and digits' );
is( $r->visual, '(?<foo_123>x)', 'named capture complex name visual' );

# multiple named captures
{
  my $p = Regexp::Parser->new;
  ok( $p->regex('(?<a>x)(?<b>y)'), 'multiple named captures' );
  is( $p->visual, '(?<a>x)(?<b>y)', 'multiple named captures visual' );
  is( $p->nparen, 2, 'two named captures counted' );
  my $nc = $p->named_captures;
  is( $nc->{a}, 1, 'named capture a is group 1' );
  is( $nc->{b}, 2, 'named capture b is group 2' );
}

# lookbehind still works
ok( $r->regex('(?<=foo)bar'), 'lookbehind still works' );
is( $r->visual, '(?<=foo)bar', 'lookbehind visual' );

ok( $r->regex('(?<!foo)bar'), 'negative lookbehind still works' );
is( $r->visual, '(?<!foo)bar', 'negative lookbehind visual' );

# === Named backreferences \k<name> and \k'name' ===

ok( $r->regex('(?<foo>bar)\k<foo>'), '\k<name> parses' );
is( $r->visual, '(?<foo>bar)\k<foo>', '\k<name> visual' );

ok( $r->regex("(?<foo>bar)\\k'foo'"), "\\k'name' parses" );
is( $r->visual, "(?<foo>bar)\\k'foo'", "\\k'name' visual" );

{
  $r->regex('(?<word>\w+)\k<word>');
  $r->parse;
  my @nodes = @{ $r->root };
  # nodes[0] = named_open, nodes[1] = named_ref
  is( $nodes[1]->family, 'ref', '\k family is ref' );
  is( $nodes[1]->name, 'word', '\k name is correct' );
}

# === Possessive quantifiers ===

ok( $r->regex('a++'), 'a++ parses' );
is( $r->visual, 'a++', 'a++ visual' );

ok( $r->regex('a*+'), 'a*+ parses' );
is( $r->visual, 'a*+', 'a*+ visual' );

ok( $r->regex('a?+'), 'a?+ parses' );
is( $r->visual, 'a?+', 'a?+ visual' );

ok( $r->regex('a{2,5}+'), 'a{2,5}+ parses' );
is( $r->visual, 'a{2,5}+', 'a{2,5}+ visual' );

{
  $r->regex('a++');
  $r->parse;
  my @nodes = @{ $r->root };
  is( $nodes[0]->family, 'possessive', 'a++ top-level is possessive' );
  is( $nodes[0]->type, 'possessive', 'a++ type is possessive' );
  # The data of possessive is the quantifier
  is( $nodes[0]->data->family, 'quant', 'a++ wraps a quantifier' );
}

# possessive in complex regex
ok( $r->regex('\d++\.\d++'), 'possessive in complex pattern' );
is( $r->visual, '\d++\.\d++', 'possessive in complex pattern visual' );

# === Combined 5.10+ features ===

ok( $r->regex('(?<num>\d++)\h+\k<num>'), 'combined 5.10+ features' );
is( $r->visual, '(?<num>\d++)\h+\k<num>', 'combined 5.10+ features visual' );

ok( $r->regex('\R+\K\h*'), 'linebreak + keep + hspace' );
is( $r->visual, '\R+\K\h*', 'linebreak + keep + hspace visual' );

done_testing;
