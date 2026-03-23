use strict;
use warnings;
use Test::More;
use Regexp::Parser;

# Extended boundary types: \b{gcb}, \b{g}, \b{wb}, \b{sb}, \b{lb}
# and their negations: \B{gcb}, \B{g}, \B{wb}, \B{sb}, \B{lb}
# Added in Perl 5.22

my @boundary_types = qw(gcb g wb sb lb);

# Test \b{TYPE} parsing
for my $bt (@boundary_types) {
  my $r = Regexp::Parser->new;
  $r->regex("\\b{$bt}");
  my $tree = $r->root;

  is(scalar @$tree, 1, "\\b{$bt} parses as single node");
  is($tree->[0]->family, 'anchor', "\\b{$bt} family is anchor");
  is($tree->[0]->type, 'bound', "\\b{$bt} type is bound");
  is($tree->[0]->visual, "\\b{$bt}", "\\b{$bt} visual correct");
  is($tree->[0]->boundary_type, $bt, "\\b{$bt} boundary_type is $bt");
}

# Test \B{TYPE} parsing
for my $bt (@boundary_types) {
  my $r = Regexp::Parser->new;
  $r->regex("\\B{$bt}");
  my $tree = $r->root;

  is(scalar @$tree, 1, "\\B{$bt} parses as single node");
  is($tree->[0]->family, 'anchor', "\\B{$bt} family is anchor");
  is($tree->[0]->type, 'nbound', "\\B{$bt} type is nbound");
  is($tree->[0]->visual, "\\B{$bt}", "\\B{$bt} visual correct");
  is($tree->[0]->boundary_type, $bt, "\\B{$bt} boundary_type is $bt");
}

# Test plain \b and \B still work (no boundary_type)
{
  my $r = Regexp::Parser->new;
  $r->regex('\b');
  my $tree = $r->root;
  is(scalar @$tree, 1, '\\b parses as single node');
  is($tree->[0]->type, 'bound', '\\b type is bound');
  is($tree->[0]->visual, '\b', '\\b visual correct');
  ok(!$tree->[0]->boundary_type, '\\b has no boundary_type');
}

{
  my $r = Regexp::Parser->new;
  $r->regex('\B');
  my $tree = $r->root;
  is(scalar @$tree, 1, '\\B parses as single node');
  is($tree->[0]->type, 'nbound', '\\B type is nbound');
  is($tree->[0]->visual, '\B', '\\B visual correct');
  ok(!$tree->[0]->boundary_type, '\\B has no boundary_type');
}

# Round-trip tests
my @roundtrip_patterns = (
  '\b{wb}',
  '\B{gcb}',
  '\b{sb}foo\b{lb}',
  '(?:\b{wb}x)+',
  '\b{g}.\B{wb}',
  'a\b{wb}b',
);

for my $pat (@roundtrip_patterns) {
  my $r = Regexp::Parser->new;
  $r->regex($pat);
  my $vis1 = $r->visual;

  $r = Regexp::Parser->new;
  $r->regex($vis1);
  my $vis2 = $r->visual;

  is($vis2, $vis1, "round-trip: $pat");
}

# Extended boundaries in character classes: \b should still be backspace
{
  my $r = Regexp::Parser->new;
  $r->regex('[\b]');
  my $tree = $r->root;
  is($tree->[0]->family, 'anyof', '[\b] is anyof');
}

# Mixed with regular content
{
  my $r = Regexp::Parser->new;
  $r->regex('foo\b{wb}bar');
  my $tree = $r->root;
  is(scalar @$tree, 3, 'foo\\b{wb}bar has 3 nodes');
  is($tree->[0]->visual, 'foo', 'first node is exact');
  is($tree->[1]->visual, '\b{wb}', 'second node is boundary');
  is($tree->[1]->boundary_type, 'wb', 'boundary_type is wb');
  is($tree->[2]->visual, 'bar', 'third node is exact');
}

done_testing;
