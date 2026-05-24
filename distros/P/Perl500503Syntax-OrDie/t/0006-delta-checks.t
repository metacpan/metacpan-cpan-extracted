######################################################################
#
# 0006-delta-checks.t  Tests for constructs found by reading all
#                      perlXXXXXdelta files from perl56delta onward
#
# Each check below corresponds to a feature introduced in a specific
# Perl version and verified against the relevant delta documentation:
#
#   D01: UNITCHECK blocks                        -- Perl 5.10
#   D02: Possessive quantifiers a++ *+ ?+        -- Perl 5.10
#   D03: Recursive patterns (?PARNO) (?&n) (?R)  -- Perl 5.10
#   D04: ${^MATCH} ${^PREMATCH} ${^POSTMATCH}    -- Perl 5.10
#   D05: \g{N} relative backreference            -- Perl 5.10
#   D06: <<>> double-diamond operator            -- Perl 5.22
#   D07: /n non-capturing regex flag             -- Perl 5.22
#   D08: <<~ indented heredoc                    -- Perl 5.26
#   D09: isa infix operator                      -- Perl 5.32
#   D10: use builtin                             -- Perl 5.36
#   D11: for my ($a,$b) paired iteration         -- Perl 5.36
#   D12: ^^ / ^^= high-precedence logical XOR   -- Perl 5.40
#   D13: __CLASS__ keyword                       -- Perl 5.40
#   D14: any/all BLOCK LIST keyword operators    -- Perl 5.42
#   D15: my method / ->& lexical method call     -- Perl 5.42
#   D16: my sub / state sub lexical subroutines  -- Perl 5.18
#   D17: %hash{LIST} / %array[LIST] key/value slices -- Perl 5.20
#   D18: &. |. ^. ~. string bitwise operators    -- Perl 5.22
#   D19: \foreach reference aliasing             -- Perl 5.22
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
    # D01: UNITCHECK blocks  (Perl 5.10)
    # perl5100delta: "UNITCHECK, a new special code block has been
    # introduced, in addition to BEGIN, CHECK, INIT and END."
    # ==============================================================
    ['D01 UNITCHECK: block - detected',
        sub { violates('UNITCHECK { print "unit\n" }' . "\n") }],

    ['D01 UNITCHECK: in comment - ignored',
        sub { !violates('# UNITCHECK { }' . "\n") }],

    ['D01 UNITCHECK: in string - ignored',
        sub { !violates('my $s = "UNITCHECK { }";' . "\n") }],

    ['D01 UNITCHECK: BEGIN still ok',
        sub { !violates('BEGIN { }' . "\n") }],

    ['D01 UNITCHECK: END still ok',
        sub { !violates('END { }' . "\n") }],

    # ==============================================================
    # D02: Possessive quantifiers a++ *+ ?+ {n,m}+  (Perl 5.10)
    # perl5100delta: "Possessive Quantifiers: Perl now supports the
    # possessive quantifier syntax"
    # ==============================================================
    ['D02 possessive: a++ - detected',
        sub { violates('if ($s =~ /a++/) {}' . "\n") }],

    ['D02 possessive: a*+ - detected',
        sub { violates('if ($s =~ /a*+/) {}' . "\n") }],

    ['D02 possessive: a?+ - detected',
        sub { violates('if ($s =~ /a?+/) {}' . "\n") }],

    ['D02 possessive: a{2,3}+ - detected',
        sub { violates('if ($s =~ /a{2,3}+/) {}' . "\n") }],

    ['D02 possessive: (?:foo)++ - detected',
        sub { violates('if ($s =~ /(?:foo)++/) {}' . "\n") }],

    ['D02 possessive: $var++ not detected (postfix increment)',
        sub { !violates('$count++;' . "\n") }],

    ['D02 possessive: $a++ + $b not detected',
        sub { !violates('my $x = $a++ + $b;' . "\n") }],

    ['D02 possessive: in comment - ignored',
        sub { !violates('# /a++/ possessive' . "\n") }],

    # ==============================================================
    # D03: Recursive patterns (?PARNO) (?&name) (?R)  (Perl 5.10)
    # perl5100delta: "Recursive Patterns: It is now possible to write
    # recursive patterns without using the (??{}) construct."
    # ==============================================================
    ['D03 recursive: (?1) - detected',
        sub { violates('if ($s =~ /(?1)/) {}' . "\n") }],

    ['D03 recursive: (?-1) relative - detected',
        sub { violates('if ($s =~ /(?-1)/) {}' . "\n") }],

    ['D03 recursive: (?&name) - detected',
        sub { violates('if ($s =~ /(?&word)/) {}' . "\n") }],

    ['D03 recursive: (?R) - detected',
        sub { violates('if ($s =~ /(?R)/) {}' . "\n") }],

    ['D03 recursive: (?:) non-capture - not detected',
        sub { !violates('if ($s =~ /(?:foo)/) {}' . "\n") }],

    ['D03 recursive: (?=) lookahead - not detected',
        sub { !violates('if ($s =~ /(?=foo)/) {}' . "\n") }],

    ['D03 recursive: in comment - ignored',
        sub { !violates('# (?1) recursive' . "\n") }],

    # ==============================================================
    # D04: ${^MATCH} ${^PREMATCH} ${^POSTMATCH}  (Perl 5.10)
    # perl5100delta: "Optional pre-match and post-match captures
    # with the /p flag"
    # ==============================================================
    ['D04 ${^MATCH}: detected',
        sub { violates('print ${^MATCH};' . "\n") }],

    ['D04 ${^PREMATCH}: detected',
        sub { violates('print ${^PREMATCH};' . "\n") }],

    ['D04 ${^POSTMATCH}: detected',
        sub { violates('print ${^POSTMATCH};' . "\n") }],

    ['D04 ${^MATCH}: in comment - ignored',
        sub { !violates('# ${^MATCH} holds matched string' . "\n") }],

    ['D04 ${^MATCH}: in string - ignored',
        sub { !violates('my $s = "${^MATCH}";' . "\n") }],

    ['D04 $x normal var - not detected',
        sub { !violates('print $x;' . "\n") }],

    # ==============================================================
    # D05: \g{N} relative/absolute backreference  (Perl 5.10)
    # perl5100delta: "Relative backreferences: A new syntax \g{N}"
    # ==============================================================
    ['D05 \\g{1}: detected',
        sub { violates('if ($s =~ /(\w+)\g{1}/) {}' . "\n") }],

    ['D05 \\g{-1}: relative - detected',
        sub { violates('if ($s =~ /(\w+)\g{-1}/) {}' . "\n") }],

    ['D05 \\1: old-style OK',
        sub { !violates('if ($s =~ /(\w+)\1/) {}' . "\n") }],

    ['D05 \\g{N}: in comment - ignored',
        sub { !violates('# use \g{1} for backreference' . "\n") }],

    # ==============================================================
    # D06: <<>> double-diamond operator  (Perl 5.22)
    # perl5220delta: "<<>> is like <> but uses three-argument open"
    # ==============================================================
    ['D06 <<>>: detected',
        sub { violates('while (<<>>) { print }' . "\n") }],

    ['D06 <<>>: in comment - ignored',
        sub { !violates('# use <<>> instead of <>' . "\n") }],

    ['D06 <>: regular diamond - not detected',
        sub { !violates('while (<>) { print }' . "\n") }],

    ['D06 <ARGV>: not detected',
        sub { !violates('while (<ARGV>) { print }' . "\n") }],

    # ==============================================================
    # D07: /n non-capturing regex flag  (Perl 5.22)
    # perl5220delta: "The /n flag disallows \$1 etc."
    # ==============================================================
    ['D07 /n flag: detected',
        sub { violates('if ($s =~ /foo/n) {}' . "\n") }],

    ['D07 /n flag: with other flags - detected',
        sub { violates('if ($s =~ /foo/gin) {}' . "\n") }],

    ['D07 /g flag alone: not detected',
        sub { !violates('$s =~ s/foo/bar/g;' . "\n") }],

    ['D07 /n flag: in comment - ignored',
        sub { !violates('# /foo/n uses non-capturing' . "\n") }],

    # ==============================================================
    # D08: <<~ indented heredoc  (Perl 5.26)
    # perl5260delta: "Indented Here-docs"
    # ==============================================================
    ['D08 <<~: detected',
        sub { violates("my \$x = <<~END;\n  text\nEND\n") }],

    ['D08 <<~: in comment - ignored',
        sub { !violates('# use <<~ for indented heredoc' . "\n") }],

    ['D08 <<: regular heredoc - not detected',
        sub { !violates("my \$x = <<END;\ntext\nEND\n") }],

    # ==============================================================
    # D09: isa infix operator  (Perl 5.32, experimental)
    # perl5320delta: "A new experimental infix operator called isa"
    # ==============================================================
    ['D09 isa: infix usage - detected',
        sub { violates('if ($obj isa Foo) {}' . "\n") }],

    ['D09 isa: in comment - ignored',
        sub { !violates('# if ($obj isa Foo)' . "\n") }],

    ['D09 isa: in string - ignored',
        sub { !violates('my $s = "isa";' . "\n") }],

    # ==============================================================
    # D10: use builtin  (Perl 5.36)
    # perl5360delta: "use builtin"
    # ==============================================================
    ['D10 use builtin: detected',
        sub { violates('use builtin qw(true false);' . "\n") }],

    ['D10 use builtin: in comment - ignored',
        sub { !violates('# use builtin qw(true)' . "\n") }],

    ['D10 use strict: not detected',
        sub { !violates('use strict;' . "\n") }],

    # ==============================================================
    # D11: for my ($a,$b) paired iteration  (Perl 5.36)
    # perl5360delta: "Iterating over multiple values at a time"
    # ==============================================================
    ['D11 for my pair: detected',
        sub { violates('for my ($a,$b) (@list) {}' . "\n") }],

    ['D11 for my pair: while with my - not detected (different syntax)',
        sub { !violates('while (my ($k,$v) = each %h) {}' . "\n") }],

    ['D11 for my scalar: not detected',
        sub { !violates('for my $x (@list) {}' . "\n") }],

    ['D11 for my pair: in comment - ignored',
        sub { !violates('# for my ($a,$b) (@list)' . "\n") }],

    # ==============================================================
    # D12: ^^ high-precedence logical XOR  (Perl 5.40)
    # perl5400delta: "^^ is the high-precedence logical xor operator"
    # ==============================================================
    ['D12 ^^: infix usage - detected',
        sub { violates('my $r = $x ^^ $y;' . "\n") }],

    ['D12 ^^=: compound assignment - detected',
        sub { violates('$x ^^= $y;' . "\n") }],

    ['D12 ^^: in comment - ignored',
        sub { !violates('# $x ^^ $y exclusive or' . "\n") }],

    ['D12 ^^: in string - ignored',
        sub { !violates('my $s = "$x ^^ $y";' . "\n") }],

    ['D12 xor: low-prec xor still ok',
        sub { !violates('my $r = $x xor $y;' . "\n") }],

    # ==============================================================
    # D13: __CLASS__ keyword  (Perl 5.40)
    # perl5400delta: "__CLASS__ keyword for use inside class blocks"
    # ==============================================================
    ['D13 __CLASS__: detected',
        sub { violates('my $c = __CLASS__;' . "\n") }],

    ['D13 __CLASS__: in comment - ignored',
        sub { !violates('# use __CLASS__ inside method' . "\n") }],

    ['D13 __CLASS__: in string - ignored',
        sub { !violates('my $s = "__CLASS__";' . "\n") }],

    ['D13 __PACKAGE__: not detected',
        sub { !violates('my $p = __PACKAGE__;' . "\n") }],

    # ==============================================================
    # D14: any/all BLOCK LIST keyword operators  (Perl 5.42)
    # perl5420delta: "New any and all list-processing operators"
    # ==============================================================
    ['D14 any { }: detected',
        sub { violates('my $r = any { $_ > 0 } @list;' . "\n") }],

    ['D14 all { }: detected',
        sub { violates('my $r = all { $_ > 0 } @list;' . "\n") }],

    ['D14 any { }: in comment - ignored',
        sub { !violates('# any { $_ > 0 } @list' . "\n") }],

    ['D14 any { }: in string - ignored',
        sub { !violates('my $s = "any { }";' . "\n") }],

    # ==============================================================
    # D15: my method / ->& lexical method  (Perl 5.42)
    # perl5420delta: "Lexical method declarations with my method"
    # ==============================================================
    ['D15 my method: detected',
        sub { violates('my method foo () { return 1 }' . "\n") }],

    ['D15 ->& call: detected',
        sub { violates('$obj->&foo();' . "\n") }],

    ['D15 my method: in comment - ignored',
        sub { !violates('# my method foo () {}' . "\n") }],

    ['D15 ->& : in string - ignored',
        sub { !violates('my $s = "$obj->&foo";' . "\n") }],

    # ==============================================================
    # D16: my sub / state sub lexical subroutines  (Perl 5.18)
    # perl5180delta: "Lexical subroutines: my sub foo, state sub foo"
    # ==============================================================
    ['D16 my sub: detected',
        sub { violates('my sub foo { return 1 }' . "\n") }],

    ['D16 state sub: detected',
        sub { violates('state sub bar { return 1 }' . "\n") }],

    ['D16 my $sub: not detected (scalar, not lexical sub)',
        sub { !violates('my $sub = sub { 1 };' . "\n") }],

    ['D16 my @sub: not detected',
        sub { !violates('my @sub;' . "\n") }],

    ['D16 my sub: in comment - ignored',
        sub { !violates('# my sub foo {}' . "\n") }],

    # ==============================================================
    # D17: %hash{LIST} / %array[LIST] key/value slices  (Perl 5.20)
    # perl5200delta: "New %hash{...} and %array[...] syntax"
    # ==============================================================
    ['D17 %hash{}: detected',
        sub { violates('my %r = %h{qw(a b)};' . "\n") }],

    ['D17 %array[]: detected',
        sub { violates('my %r = %arr[1,2];' . "\n") }],

    ['D17 plain %hash=: not detected',
        sub { !violates('my %h = (a => 1);' . "\n") }],

    ['D17 %hash{}: in comment - ignored',
        sub { !violates('# %h{keys} is new in 5.20' . "\n") }],

    # ==============================================================
    # D18: &. |. ^. ~. string bitwise operators  (Perl 5.22)
    # perl5220delta: "New bitwise operators &. |. ^. ~."
    # ==============================================================
    ['D18 &.: detected',
        sub { violates('my $r = $a &. $b;' . "\n") }],

    ['D18 |.: detected',
        sub { violates('my $r = $a |. $b;' . "\n") }],

    ['D18 ^.=: detected',
        sub { violates('$x ^.= $y;' . "\n") }],

    ['D18 ~.: detected',
        sub { violates('my $r = ~.$a;' . "\n") }],

    ['D18 & without dot: not detected',
        sub { !violates('my $r = $a & $b;' . "\n") }],

    ['D18 &.: in comment - ignored',
        sub { !violates('# $a &. $b string bitwise' . "\n") }],

    # ==============================================================
    # D19: \foreach reference aliasing  (Perl 5.22)
    # perl5220delta: "Aliasing via reference in foreach"
    # ==============================================================
    ['D19 \\foreach \\$x: detected',
        sub { violates('foreach \$x (@a) {}' . "\n") }],

    ['D19 \\foreach \\my $x: detected',
        sub { violates('foreach \my $x (@a) {}' . "\n") }],

    ['D19 foreach my $x: not detected',
        sub { !violates('foreach my $x (@a) {}' . "\n") }],

    ['D19 \\foreach: in comment - ignored',
        sub { !violates('# foreach \$x (@a)' . "\n") }],

    # ==============================================================
    # Clean code: Perl 5.005_03-compatible constructs still pass
    # ==============================================================
    ['clean: for loop ok',
        sub { !violates('for my $i (0..9) {}' . "\n") }],

    ['clean: $a++ increment ok',
        sub { !violates('$a++;' . "\n") }],

    ['clean: <> diamond ok',
        sub { !violates('while (<>) { print }' . "\n") }],

    ['clean: heredoc ok',
        sub { !violates("my \$x = <<END;\ntext\nEND\n") }],

    ['clean: UNIVERSAL::isa ok',
        sub { !violates('if (UNIVERSAL::isa($x, "Foo")) {}' . "\n") }],

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
