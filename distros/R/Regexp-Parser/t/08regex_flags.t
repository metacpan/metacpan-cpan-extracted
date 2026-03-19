use Test;
BEGIN { plan tests => 18 };
use Regexp::Parser;
ok(1);

my $r = Regexp::Parser->new;

# Test 1: regex with 'x' flag -- whitespace should be ignored
ok( $r->regex(' foo [ ] bar ', 'x') );
ok( $r->visual, 'foo[ ]bar' ) || print "# got: ", $r->visual, "\n";

# Test 2: regex with 'i' flag -- exact nodes should become exactf
ok( $r->regex('abc', 'i') );
ok( my $w = $r->walker and 1 );
while (my ($n, $d) = $w->()) {
  chomp(my $exp = <DATA>);
  ok( join("\t", $d, $n->family, $n->type, $n->visual), $exp );
}
ok( scalar(<DATA>), "---\n" );

# Test 3: regex with 'is' flags combined
ok( $r->regex('.', 'is') );
$w = $r->walker;
my ($n) = $w->();
ok( $n->type, 'sany' );  # /s makes . match \n, which is 'sany' type

# Test 4: regex with no flags (default behavior unchanged)
ok( $r->regex('abc') );
$w = $r->walker;
($n) = $w->();
ok( $n->type, 'exact' );  # should NOT be exactf

# Test 5: regex with 'x' flag -- comments should be ignored
ok( $r->regex('a # comment', 'x') );
ok( $r->visual, 'a' ) || print "# got: ", $r->visual, "\n";

# Test 6: flags do not persist between regex() calls
ok( $r->regex('abc', 'i') );
ok( $r->regex('abc') );
$w = $r->walker;
($n) = $w->();
ok( $n->type, 'exact' );

# Test 7: regex with 'm' flag
ok( $r->regex('^a', 'm') );
$w = $r->walker;
($n) = $w->();
ok( $n->type, 'mbol' );  # /m makes ^ match \n boundaries (mbol)

__DATA__
0	exact	exactf	abc
---
