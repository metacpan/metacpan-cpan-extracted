use strict;
use warnings;
use Test::More;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# Helper: parse and return root tree
sub parse_rx {
  my ($rx) = @_;
  $r->regex($rx) or die "regex() failed for: $rx";
  return $r->root;
}

# (?R) -- whole-pattern recursion
{
  my $tree = parse_rx('(?R)');
  is(scalar @$tree, 1, '(?R) produces one node');
  isa_ok($tree->[0], 'Regexp::Parser::recurse');
  is($tree->[0]->family, 'recurse', '(?R) family is recurse');
  is($tree->[0]->type, 'recurse', '(?R) type is recurse');
  is($tree->[0]->num, 0, '(?R) num is 0');
  is($tree->[0]->visual, '(?R)', '(?R) visual');
  is($tree->[0]->qr, '(?R)', '(?R) qr');
}

# (?0) -- equivalent to (?R)
{
  my $tree = parse_rx('(?0)');
  is(scalar @$tree, 1, '(?0) produces one node');
  is($tree->[0]->num, 0, '(?0) num is 0');
  is($tree->[0]->visual, '(?0)', '(?0) visual');
}

# (?1) -- numbered group recursion
{
  my $tree = parse_rx('(a)(?1)');
  my $recurse = $tree->[1];
  isa_ok($recurse, 'Regexp::Parser::recurse');
  is($recurse->num, 1, '(?1) num is 1');
  is($recurse->visual, '(?1)', '(?1) visual');
}

# (?+1) -- relative forward recursion
{
  my $tree = parse_rx('(?+1)(a)');
  my $recurse = $tree->[0];
  isa_ok($recurse, 'Regexp::Parser::recurse');
  is($recurse->num, '+1', '(?+1) num is +1');
  is($recurse->visual, '(?+1)', '(?+1) visual');
}

# (?-1) -- relative backward recursion
{
  my $tree = parse_rx('(a)(?-1)');
  my $recurse = $tree->[1];
  isa_ok($recurse, 'Regexp::Parser::recurse');
  is($recurse->num, '-1', '(?-1) num is -1');
  is($recurse->visual, '(?-1)', '(?-1) visual');
}

# (?&name) -- named recursion
{
  my $tree = parse_rx('(?<foo>a)(?&foo)');
  my $recurse = $tree->[1];
  isa_ok($recurse, 'Regexp::Parser::named_recurse');
  is($recurse->family, 'recurse', '(?&name) family is recurse');
  is($recurse->type, 'named_recurse', '(?&name) type is named_recurse');
  is($recurse->name, 'foo', '(?&foo) name is foo');
  is($recurse->visual, '(?&foo)', '(?&foo) visual');
  is($recurse->qr, '(?&foo)', '(?&foo) qr');
}

# (?P<name>...) -- Python named capture
{
  my $tree = parse_rx('(?P<bar>x)');
  is(scalar @$tree, 1, '(?P<bar>x) produces one node');
  isa_ok($tree->[0], 'Regexp::Parser::named_open');
  is($tree->[0]->name, 'bar', '(?P<bar>) name is bar');
  is($tree->[0]->visual, '(?<bar>x)', '(?P<bar>x) normalizes to (?<bar>x)');
}

# (?P=name) -- Python named backreference
{
  my $tree = parse_rx('(?P<baz>a)(?P=baz)');
  my $ref = $tree->[1];
  isa_ok($ref, 'Regexp::Parser::named_ref');
  is($ref->name, 'baz', '(?P=baz) name is baz');
  is($ref->visual, '(?P=baz)', '(?P=baz) visual');
}

# (?P>name) -- Python named recursion
{
  my $tree = parse_rx('(?P<qux>a)(?P>qux)');
  my $recurse = $tree->[1];
  isa_ok($recurse, 'Regexp::Parser::named_recurse');
  is($recurse->name, 'qux', '(?P>qux) name is qux');
  is($recurse->visual, '(?P>qux)', '(?P>qux) visual');
  is($recurse->qr, '(?&qux)', '(?P>qux) qr normalizes to (?&qux)');
}

# Round-trip: parse -> visual -> re-parse -> visual
my @roundtrip = (
  '(?R)',
  '(?0)',
  '(a)(?1)',
  '(?+1)(a)',
  '(a)(?-1)',
  '(?<foo>a)(?&foo)',
  # (?P<>...) normalizes to (?<>...), so round-trip starts from normalized form
  '(?<bar>x)',
);

for my $rx (@roundtrip) {
  my $tree = parse_rx($rx);
  my $vis1 = join '', map { $_->visual } @$tree;
  $tree = parse_rx($vis1);
  my $vis2 = join '', map { $_->visual } @$tree;
  is($vis2, $vis1, "round-trip: $rx");
}

# Embedded in larger patterns
{
  my $tree = parse_rx('a(?:b(?R)c)d');
  my $vis = join '', map { $_->visual } @$tree;
  is($vis, 'a(?:b(?R)c)d', '(?R) embedded in non-capturing group');
}

{
  my $tree = parse_rx('(?<list>\\w+(?:,(?&list))?)');
  my $vis = join '', map { $_->visual } @$tree;
  is($vis, '(?<list>\\w+(?:,(?&list))?)', 'named recursion in realistic pattern');
}

# Multiple recursion references
{
  my $tree = parse_rx('(a)(b)(?1)(?2)');
  is($tree->[2]->num, 1, 'first recursion refers to group 1');
  is($tree->[3]->num, 2, 'second recursion refers to group 2');
}

# (?R) with quantifier
{
  my $tree = parse_rx('a(?R)?b');
  my $vis = join '', map { $_->visual } @$tree;
  is($vis, 'a(?R)?b', '(?R) with ? quantifier');
}

# Higher numbered groups
{
  my $tree = parse_rx('(a)(b)(c)(?3)');
  is($tree->[3]->num, 3, '(?3) references group 3');
  is($tree->[3]->visual, '(?3)', '(?3) visual');
}

# (?R) inside alternation
{
  my $tree = parse_rx('a|(?R)b');
  my $vis = join '', map { $_->visual } @$tree;
  is($vis, 'a|(?R)b', '(?R) inside alternation');
}

done_testing;
