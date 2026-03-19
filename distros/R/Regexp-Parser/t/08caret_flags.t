use strict;
use warnings;
use Test::More tests => 22;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# Basic (?^:...) - non-capturing group with default flags
ok( $r->regex('(?^:abc)'), 'parse (?^:abc)' );
is( $r->visual, '(?^:abc)', 'visual for (?^:abc)' );
ok( "abc" =~ $r->qr, 'qr for (?^:abc) matches' );
ok( "ABC" !~ $r->qr, 'qr for (?^:abc) case-sensitive' );

# (?^i:...) - reset then turn on i flag
ok( $r->regex('(?^i:abc)'), 'parse (?^i:abc)' );
is( $r->visual, '(?^i:abc)', 'visual for (?^i:abc)' );
ok( "ABC" =~ $r->qr, 'qr for (?^i:abc) is case-insensitive' );

# (?^) as inline flag assertion
ok( $r->regex('(?i)abc(?^)def'), 'parse (?i)abc(?^)def' );
is( $r->visual, '(?i)abc(?^)def', 'visual for inline (?^)' );

# Verify (?^) resets flags - walker check
{
  ok( $r->regex('(?i)abc(?^)def'), 'parse for walker test' );
  my $w = $r->walker;
  my @nodes;
  while (my ($n, $d) = $w->()) {
    push @nodes, [$d, $n->family, $n->type, $n->visual];
  }
  is( $nodes[0][2], 'flags', 'first node is flags' );
  is( $nodes[0][3], '(?i)', 'first node is (?i)' );
  is( $nodes[1][2], 'exactf', 'abc is case-insensitive (exactf)' );
  is( $nodes[2][3], '(?^)', 'caret flag reset node' );
  is( $nodes[3][2], 'exact', 'def is case-sensitive after (?^)' );
}

# Parse output from modern Perl's qr//
my $qr_str = "" . qr/^a(b|c)/;
ok( $r->regex($qr_str), "parse qr// output: $qr_str" );
like( $r->visual, qr/\Q^a(b|c)\E/, 'visual contains original pattern' );
ok( "ab" =~ $r->qr, 'qr matches ab' );
ok( "ac" =~ $r->qr, 'qr matches ac' );
ok( "ad" !~ $r->qr, 'qr does not match ad' );

# (?^ix:...) - multiple flags after caret
ok( $r->regex('(?^ix:a b)'), 'parse (?^ix:a b)' );
is( $r->visual, '(?^ix:ab)', 'visual for (?^ix:a b) strips whitespace' );
