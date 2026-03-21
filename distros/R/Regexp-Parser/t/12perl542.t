use strict;
use warnings;
use Test::More;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# ========================================
# \o{NNN} octal escape (Perl 5.14+)
# ========================================

subtest '\o{NNN} octal escape' => sub {
  ok($r->regex('\o{101}'), 'parse \\o{101}');
  is($r->visual, '\o{101}', 'visual for \\o{101}');

  ok($r->regex('\o{60}'), 'parse \\o{60}');
  is($r->visual, '\o{60}', 'visual for \\o{60}');

  ok($r->regex('\o{0}'), 'parse \\o{0}');
  is($r->visual, '\o{0}', 'visual for \\o{0}');

  # inside character class
  ok($r->regex('[\o{101}-\o{132}]'), 'parse \\o{} in character class');
  is($r->visual, '[\o{101}-\o{132}]', 'visual for \\o{} in char class');

  # round-trip
  ok($r->regex('\o{101}\o{102}'), 'parse multiple \\o{}');
  my $vis1 = $r->visual;
  ok($r->regex($vis1), 're-parse visual output');
  is($r->visual, $vis1, 'round-trip for \\o{}');
};

# ========================================
# (*VERB) backtracking control verbs (Perl 5.10+)
# ========================================

subtest '(*VERB) backtracking control verbs' => sub {
  # (*FAIL)
  ok($r->regex('a(*FAIL)'), 'parse (*FAIL)');
  is($r->visual, 'a(*FAIL)', 'visual for (*FAIL)');

  # (*F) — short form of (*FAIL)
  ok($r->regex('(*F)'), 'parse (*F)');
  is($r->visual, '(*F)', 'visual for (*F)');

  # (*ACCEPT)
  ok($r->regex('foo(*ACCEPT)bar'), 'parse (*ACCEPT)');
  is($r->visual, 'foo(*ACCEPT)bar', 'visual for (*ACCEPT)');

  # (*SKIP)
  ok($r->regex('(*SKIP)'), 'parse (*SKIP)');
  is($r->visual, '(*SKIP)', 'visual for (*SKIP)');

  # (*PRUNE)
  ok($r->regex('(*PRUNE)'), 'parse (*PRUNE)');
  is($r->visual, '(*PRUNE)', 'visual for (*PRUNE)');

  # (*COMMIT)
  ok($r->regex('(*COMMIT)'), 'parse (*COMMIT)');
  is($r->visual, '(*COMMIT)', 'visual for (*COMMIT)');

  # (*THEN)
  ok($r->regex('(*THEN)'), 'parse (*THEN)');
  is($r->visual, '(*THEN)', 'visual for (*THEN)');

  # (*MARK:name) — verb with argument
  ok($r->regex('(*MARK:foo)'), 'parse (*MARK:foo)');
  is($r->visual, '(*MARK:foo)', 'visual for (*MARK:foo)');

  # (*SKIP:name)
  ok($r->regex('(*SKIP:label)'), 'parse (*SKIP:label)');
  is($r->visual, '(*SKIP:label)', 'visual for (*SKIP:label)');

  # round-trip
  ok($r->regex('a(*MARK:x)b|c(*SKIP)d'), 'parse verb in alternation');
  my $vis = $r->visual;
  ok($r->regex($vis), 're-parse verb visual');
  is($r->visual, $vis, 'round-trip for verbs');

  # verb node properties
  ok($r->regex('(*MARK:test)'), 'parse verb for property check');
  $r->parse;
  my $root = $r->root;
  my $verb = $root->[0];
  is($verb->family, 'verb', 'verb family');
  is($verb->name, 'MARK', 'verb name');
  is($verb->arg, 'test', 'verb arg');
};

# ========================================
# (?|...) branch reset groups (Perl 5.10+)
# ========================================

subtest '(?|...) branch reset groups' => sub {
  ok($r->regex('(?|(a)|(b))'), 'parse (?|...)');
  is($r->visual, '(?|(a)|(b))', 'visual for (?|...)');

  ok($r->regex('(?|foo|bar)'), 'parse (?|...) without captures');
  is($r->visual, '(?|foo|bar)', 'visual for (?|...) without captures');

  # nested
  ok($r->regex('(?|(?|(a)))'), 'parse nested (?|...)');
  is($r->visual, '(?|(?|(a)))', 'visual for nested (?|...)');

  # round-trip
  ok($r->regex('(?|(x)|(y)|(z))'), 'parse (?|...) 3 branches');
  my $vis = $r->visual;
  ok($r->regex($vis), 're-parse branch_reset visual');
  is($r->visual, $vis, 'round-trip for (?|...)');

  # node properties
  ok($r->regex('(?|a|b)'), 'parse (?|...) for property check');
  $r->parse;
  my $root = $r->root;
  is($root->[0]->family, 'group', 'branch_reset family');
  is($root->[0]->type, 'branch_reset', 'branch_reset type');
};

# ========================================
# (*assertion:...) alphabetic assertions (Perl 5.28+)
# ========================================
# The alphabetic assertion forms are syntactic sugar.
# They reuse the underlying assertion objects, so visual()
# renders in the traditional form (e.g., (?=...) not (*pla:...)).

subtest '(*assertion:...) alphabetic assertions' => sub {
  # positive lookahead: (*pla:...) => (?=...)
  ok($r->regex('(*positive_lookahead:foo)'), 'parse (*positive_lookahead:...)');
  is($r->visual, '(?=foo)', 'visual normalizes to (?=...)');

  ok($r->regex('(*pla:foo)'), 'parse (*pla:...)');
  is($r->visual, '(?=foo)', 'pla normalizes to (?=...)');

  # negative lookahead: (*nla:...) => (?!...)
  ok($r->regex('(*negative_lookahead:bar)'), 'parse (*negative_lookahead:...)');
  is($r->visual, '(?!bar)', 'visual normalizes to (?!...)');

  ok($r->regex('(*nla:bar)'), 'parse (*nla:...)');
  is($r->visual, '(?!bar)', 'nla normalizes to (?!...)');

  # positive lookbehind: (*plb:...) => (?<=...)
  ok($r->regex('(*positive_lookbehind:x)'), 'parse (*positive_lookbehind:...)');
  is($r->visual, '(?<=x)', 'visual normalizes to (?<=...)');

  ok($r->regex('(*plb:x)'), 'parse (*plb:...)');
  is($r->visual, '(?<=x)', 'plb normalizes to (?<=...)');

  # negative lookbehind: (*nlb:...) => (?<!...)
  ok($r->regex('(*negative_lookbehind:y)'), 'parse (*negative_lookbehind:...)');
  is($r->visual, '(?<!y)', 'visual normalizes to (?<!...)');

  ok($r->regex('(*nlb:y)'), 'parse (*nlb:...)');
  is($r->visual, '(?<!y)', 'nlb normalizes to (?<!...)');

  # atomic: (*atomic:...) => (?>...)
  ok($r->regex('(*atomic:abc)'), 'parse (*atomic:...)');
  is($r->visual, '(?>abc)', 'atomic normalizes to (?>...)');

  # script_run (new type, keeps its own visual)
  ok($r->regex('(*script_run:\d+)'), 'parse (*script_run:...)');
  is($r->visual, '(*script_run:\d+)', 'visual for (*script_run:...)');

  ok($r->regex('(*sr:\w+)'), 'parse (*sr:...)');
  # (*sr:...) creates a script_run object — visual normalizes to canonical form
  is($r->visual, '(*script_run:\w+)', 'sr normalizes to (*script_run:...)');

  # atomic_script_run — (*atomic_script_run:...) normalizes to (*asr:...)
  ok($r->regex('(*atomic_script_run:\d+)'), 'parse (*atomic_script_run:...)');
  is($r->visual, '(*asr:\d+)', 'atomic_script_run normalizes to (*asr:...)');

  ok($r->regex('(*asr:\d+)'), 'parse (*asr:...)');
  is($r->visual, '(*asr:\d+)', 'visual for (*asr:...)');

  # round-trip: alpha assertions normalize, so round-trip through normalized form
  ok($r->regex('(*pla:x)(*nlb:y)'), 'parse combined alpha assertions');
  my $vis = $r->visual;
  ok($r->regex($vis), 're-parse alpha assertion visual');
  is($r->visual, $vis, 'round-trip for alpha assertions');
};

# ========================================
# /xx flag (Perl 5.26+)
# ========================================
# The /xx flag extends /x to also ignore unescaped whitespace and
# comments inside character classes.  The basic /x behavior (ignoring
# whitespace outside character classes) is the same for both /x and /xx.

subtest '/xx flag' => sub {
  # (?xx:...) should be parseable — whitespace consumed by /x behavior
  ok($r->regex('(?xx:foo)'), 'parse (?xx:...)');
  is($r->visual, '(?xx:foo)', 'visual for (?xx:...)');

  # (?xx) flag-only assertion
  ok($r->regex('(?xx)'), 'parse (?xx) flag assertion');
  is($r->visual, '(?xx)', 'visual for (?xx) flag assertion');

  # via regex() flags parameter — double x in flags string
  ok($r->regex('foo', 'xx'), 'parse with xx flag parameter');
  is($r->visual, 'foo', 'visual under xx flag');

  # /xx should parse and accept double-x in combination with others
  ok($r->regex('(?ixx:test)'), 'parse (?ixx:...)');
  is($r->visual, '(?ixx:test)', 'visual for (?ixx:...)');

  # round-trip
  ok($r->regex('(?xx:abc)'), 'parse (?xx:abc)');
  my $vis = $r->visual;
  ok($r->regex($vis), 're-parse xx visual');
  is($r->visual, $vis, 'round-trip for (?xx:...)');
};

done_testing();
