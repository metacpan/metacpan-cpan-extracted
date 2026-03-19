# Tests for \g{N} backreferences and /a/d/l/u modifier flags (Perl 5.10+/5.14+)

use Test;
BEGIN { plan tests => 31 };
use Regexp::Parser;
ok(1); # loaded

my $r = Regexp::Parser->new;

# --- \g{N} absolute backreferences ---

# \g{1} — equivalent to \1
ok( $r->regex('(a)\\g{1}') );
ok( $r->visual, '(a)\\g{1}' );

# \g1 — no-braces form
ok( $r->regex('(a)\\g1') );
ok( $r->visual, '(a)\\g1' );

# \g{2} — reference to second capture group
ok( $r->regex('(a)(b)\\g{2}') );
ok( $r->visual, '(a)(b)\\g{2}' );

# --- \g{-N} relative backreferences ---

# \g{-1} — refer to the most recent capture group
ok( $r->regex('(a)\\g{-1}') );
ok( $r->visual, '(a)\\g{-1}' );

# \g{-2} with two groups — refer to first group
ok( $r->regex('(a)(b)\\g{-2}') );
ok( $r->visual, '(a)(b)\\g{-2}' );

# --- qr() for backrefs ---

# \g{1} should produce working qr (emits \1 for Perl)
$r->regex('(a)\\g{1}');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# \g{-1} should produce working qr
$r->regex('(a)\\g{-1}');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# \g1 should produce working qr
$r->regex('(a)\\g1');
ok( "aa" =~ $r->qr );
ok( "ab" !~ $r->qr );

# --- /a, /d, /l, /u charset flags ---

# (?u:...) — unicode flag
ok( $r->regex('(?u:abc)') );
ok( $r->visual, '(?u:abc)' );

# (?a:...) — ASCII flag
ok( $r->regex('(?a:abc)') );
ok( $r->visual, '(?a:abc)' );

# (?l:...) — locale flag
ok( $r->regex('(?l:abc)') );
ok( $r->visual, '(?l:abc)' );

# (?d:...) — default flag
ok( $r->regex('(?d:abc)') );
ok( $r->visual, '(?d:abc)' );

# combined flags: (?ui:...)
ok( $r->regex('(?ui:abc)') );
ok( $r->visual, '(?ui:abc)' );

# flag assertion: (?u) inline
ok( $r->regex('(?u)abc') );

# --- error cases ---

# \g{99} — nonexistent group should error on parse
$r->regex('(a)\\g{99}');
eval { $r->visual };
ok( $@ =~ /nonexistent group/ );

# \g{-5} — relative ref too far back should error on parse
$r->regex('(a)\\g{-5}');
eval { $r->visual };
ok( $@ =~ /nonexistent group/ );

# \g without number or braces should fail at regex() time
ok( !$r->regex('(a)\\g') );
