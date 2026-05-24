######################################################################
#
# 0004-new-checks.t  Tests for newly added static violation checks
#
# Covers constructs that were missing from the original blacklist
# and caused real implementation bugs:
#
#   N1: @+ / @- match-position arrays ($+[N], $-[N], @+, @-)
#       -- introduced in Perl 5.6
#   N2: CHECK / INIT phase blocks
#       -- introduced in Perl 5.6
#   N3: v-string notation (v1.2.3)
#       -- introduced in Perl 5.6
#   N4: $^V version object
#       -- introduced in Perl 5.6
#   N5: :lvalue subroutine attribute
#       -- introduced in Perl 5.6
#   N6: use encoding
#       -- introduced in Perl 5.8
#   N7: defined-or operator (two slashes, standalone)
#       -- introduced in Perl 5.10
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

BEGIN {
    require Perl500503Syntax::OrDie;
    Perl500503Syntax::OrDie::_install_runtime_guards();
}

sub violates {
    my ($src) = @_;
    my @_v = Perl500503Syntax::OrDie::_check_source($src, 'test');
    return @_v ? 1 : 0;
}

use vars qw(@tests);
@tests = (

    # ==============================================================
    # N1: @+ / @- match-position arrays  (Perl 5.6)
    # The original implementation mistakenly used $+[0] (Perl 5.6+)
    # instead of length($&), causing "Use of uninitialized value".
    # ==============================================================
    ['N1 @+: $+[0] in code - detected',
        sub { violates('if ($s =~ /foo/) { my $end = $+[0] }' . "\n") }],

    ['N1 @+: $+[1] in code - detected',
        sub { violates('my $pos = $+[1];' . "\n") }],

    ['N1 @+: $-[0] in code - detected',
        sub { violates('my $start = $-[0];' . "\n") }],

    ['N1 @+: @+ array in code - detected',
        sub { violates('my @ends = @+;' . "\n") }],

    ['N1 @+: @- array in code - detected',
        sub { violates('my @starts = @-;' . "\n") }],

    ['N1 @+: $+[N] in comment - ignored',
        sub { !violates('# use $+[0] for end position' . "\n") }],

    ['N1 @+: $+[N] in string - ignored',
        sub { !violates('my $s = \'$+[0]\';' . "\n") }],

    ['N1 @+: plain @array not detected',
        sub { !violates('my @result = (1, 2, 3);' . "\n") }],

    ['N1 @+: $_ not detected',
        sub { !violates('$_ = "hello";' . "\n") }],

    # ==============================================================
    # N2: CHECK / INIT phase blocks  (Perl 5.6)
    # ==============================================================
    ['N2 CHECK: real code - detected',
        sub { violates('CHECK { print "check\n" }' . "\n") }],

    ['N2 INIT: real code - detected',
        sub { violates('INIT { my $x = 1; }' . "\n") }],

    ['N2 CHECK: in comment - ignored',
        sub { !violates('# CHECK { }' . "\n") }],

    ['N2 INIT: in string - ignored',
        sub { !violates('my $s = \'INIT { }\';' . "\n") }],

    ['N2 BEGIN: not detected (Perl 5.004)',
        sub { !violates('BEGIN { }' . "\n") }],

    ['N2 END: not detected (Perl 5.004)',
        sub { !violates('END { }' . "\n") }],

    ['N2 CHECKOUT: not detected (word boundary)',
        sub { !violates('my $x = CHECKOUT;' . "\n") }],

    ['N2 INITIALIZE: not detected (word boundary)',
        sub { !violates('sub INITIALIZE { }' . "\n") }],

    # ==============================================================
    # N3: v-string notation  (Perl 5.6)
    # ==============================================================
    ['N3 vstring: v1.2.3 assignment - detected',
        sub { violates('my $v = v1.2.3;' . "\n") }],

    ['N3 vstring: v5.6.0 in comparison - detected',
        sub { violates('if ($] >= v5.6.0) { }' . "\n") }],

    ['N3 vstring: in comment - ignored',
        sub { !violates('# version v1.2.3 required' . "\n") }],

    ['N3 vstring: in string - ignored',
        sub { !violates('my $s = "v1.2.3";' . "\n") }],

    ['N3 vstring: use v5.6 detected (also caught by use VERSION check)',
        sub { violates('use v5.6;' . "\n") }],

    # ==============================================================
    # N4: $^V version object  (Perl 5.6)
    # ==============================================================
    ['N4 $^V: in comparison - detected',
        sub { violates('if ($^V gt v5.6.0) { }' . "\n") }],

    ['N4 $^V: assignment - detected',
        sub { violates('my $ver = $^V;' . "\n") }],

    ['N4 $^V: in comment - ignored',
        sub { !violates('# use $^V for version' . "\n") }],

    ['N4 $^V: in string - ignored',
        sub { !violates('my $s = \'$^V\';' . "\n") }],

    ['N4 $^W: not detected ($^W is Perl 5.004)',
        sub { !violates('local $^W = 1;' . "\n") }],

    ['N4 $^O: not detected ($^O is Perl 5.004)',
        sub { !violates('print $^O;' . "\n") }],

    # ==============================================================
    # N5: :lvalue subroutine attribute  (Perl 5.6)
    # ==============================================================
    ['N5 lvalue: sub foo : lvalue - detected',
        sub { violates('sub foo : lvalue { $_[0] }' . "\n") }],

    ['N5 lvalue: sub bar :lvalue - detected',
        sub { violates('sub bar :lvalue { $_[0] }' . "\n") }],

    ['N5 lvalue: in comment - ignored',
        sub { !violates('# sub foo : lvalue { }' . "\n") }],

    ['N5 lvalue: plain sub not detected',
        sub { !violates('sub baz { return 1; }' . "\n") }],

    ['N5 lvalue: word "lvalue" in string - ignored',
        sub { !violates('my $s = "lvalue sub";' . "\n") }],

    # ==============================================================
    # N6: use encoding  (Perl 5.8)
    # ==============================================================
    ['N6 encoding: use encoding "utf8" - detected',
        sub { violates('use encoding "utf8";' . "\n") }],

    ['N6 encoding: use encoding "euc-jp" - detected',
        sub { violates('use encoding "euc-jp";' . "\n") }],

    ['N6 encoding: in comment - ignored',
        sub { !violates('# use encoding "utf8"' . "\n") }],

    ['N6 encoding: use Encode - not detected (different module)',
        sub { !violates('use Encode;' . "\n") }],

    ['N6 encoding: use strict - not detected',
        sub { !violates('use strict;' . "\n") }],

    # ==============================================================
    # N7: defined-or operator (two slashes) standalone  (Perl 5.10)
    # The original blacklist checked defined-or-assign but not two-slash alone.
    # ==============================================================
    ['N7 defor: $x = $y defor "default" - detected',
        sub { my $s = 'my $x = $y ' . join('','/','/') . ' "default";' . "\n"; violates($s) }],

    ['N7 defor: if ($x defor 0) - detected',
        sub { my $s = 'if ($x ' . join('','/','/') . ' 0) { }' . "\n"; violates($s) }],

    ['N7 defor: return $val defor $default - detected',
        sub { my $s = 'return $val ' . join('','/','/') . ' $default;' . "\n"; violates($s) }],

    ['N7 defor-assign: still detected (existing check)',
        sub { my $s = '$x ' . join('','/','/') . '= 1;' . "\n"; violates($s) }],

    ['N7 defor: s/foo/bar/ - not detected',
        sub { !violates('$s =~ s/foo/bar/;' . "\n") }],

    ['N7 defor: m// empty regex - not detected',
        sub { !violates('if ($s =~ m//) { }' . "\n") }],

    ['N7 defor: in comment - ignored',
        sub { my $s = '# $x = $y ' . join('','/','/') . ' "default"' . "\n"; !violates($s) }],

    ['N7 defor: in string - ignored',
        sub { my $s2 = 'my $s = \'$x ' . join('','/','/') . ' $y\';' . "\n"; !violates($s2) }],

    ['N7 defor: || not detected (Perl 5.004 ok)',
        sub { !violates('my $x = $a || $b;' . "\n") }],

    # ==============================================================
    # Clean code: confirm that normal Perl 5.005_03 code still passes
    # ==============================================================
    ['clean: $] version check ok',
        sub { !violates('if ($] >= 5.005_03) { }' . "\n") }],

    ['clean: pos() ok',
        sub { !violates('my $p = pos($str);' . "\n") }],

    ['clean: length($&) ok',
        sub { !violates('my $n = length($&);' . "\n") }],

    ['clean: $& match variable ok',
        sub { !violates('print $&;' . "\n") }],

    ['clean: regular array @arr ok',
        sub { !violates('my @arr = (1,2,3);' . "\n") }],

    ['clean: BEGIN/END blocks ok',
        sub { !violates('BEGIN { }' . "\n" . 'END { }' . "\n") }],

);

print "1.." . scalar(@tests) . "\n";
my $n = 0;
for my $t (@tests) {
    $n++;
    my ($label, $code) = @{$t};
    my $result = eval { $code->() };
    my $ok     = $result && !$@;
    print +($ok ? '' : 'not ') . "ok $n - $label\n";
    print "# EVAL ERROR: $@\n" if $@ && $@ !~ /VIOLATION/;
}
