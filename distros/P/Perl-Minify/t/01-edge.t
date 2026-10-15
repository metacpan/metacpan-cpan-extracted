#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify);

# 1. Empty string input -> no crash
my $r1 = minify('');
ok(defined($r1), 'empty string returns defined');

# 2. Only comments/POD -> near-empty output
my $r2 = minify("# comment\n=pod\nPOD\n=cut\n");
ok(defined($r2), 'only comments/POD returns defined');
ok($r2 eq '' || $r2 =~ /^\s*$/, 'only comments/POD produces empty output') or diag "got: [$r2]";

# 3. "use strict; use warnings;" -> NOT "usestrict"
my $r3 = minify('use strict; use warnings;');
ok(defined($r3), 'use strict/warnings returns defined');
ok($r3 =~ /\buse\s+strict\b/, 'use strict preserved as word') or diag "got: $r3";
ok($r3 =~ /\buse\s+warnings\b/, 'use warnings preserved as word') or diag "got: $r3";

# 4. "$fh $data" -> stays separated by a space
my $r5 = minify('my ($fh, $data); $fh $data;');
ok(defined($r5), 'symbol separation returns defined');
ok($r5 =~ /\$fh\s+\$data/, '$fh $data separated by space') or diag "got: $r5";

# 5. Punctuation-op spacing: "$a + $b" -> "$a+$b"
my $r6 = minify('my $a; $a + $b;');
ok(defined($r6), 'punct op returns defined');
ok($r6 !~ /\$a\s+\+\s+\$b/, '$a + $b collapsed to $a+$b') or diag "got: $r6";

# 6. Bracket spacing: "( $x )" -> "($x)"
my $r7 = minify('my $x; print( $x );');
ok(defined($r7), 'bracket spacing returns defined');
ok($r7 !~ /\(\s+\$x\s+\)/, 'paren spacing collapsed') or diag "got: $r7";

# 7. Hash bareword access "$h{key}" preserved
my $r8 = minify('sub f { my $h; $h{key}; }');
ok(defined($r8), 'hash access returns defined');
ok($r8 =~ /\$h\{key\}/, '$h{key} preserved') or diag "got: $r8";

# 8. __DATA__ preserved unchanged
my $r9 = minify("use strict;\n__DATA__\nhello\nworld\n");
ok(defined($r9), '__DATA__ returns defined');
ok($r9 =~ /__DATA__/, '__DATA__ preserved') or diag "got: $r9";

# 9. __END__ preserved unchanged
my $r10 = minify("use strict;\n__END__\nhello\nworld\n");
ok(defined($r10), '__END__ returns defined');
ok($r10 =~ /__END__/, '__END__ preserved') or diag "got: $r10";

# 10. Unicode in strings preserved
my $r11 = minify("print \"héllo wörld\\n\";");
ok(defined($r11), 'Unicode returns defined');
ok($r11 =~ /héllo wörld/, 'Unicode in strings preserved') or diag "got: $r11";

# 11. Safe semicolon elision before a block close.
my $r12 = minify('sub f { my $x = 1; return $x; }');
ok(defined($r12), 'semicolon elision returns defined');
like($r12, qr/my\$x=1;return\$x}/, 'expression terminators before } are removed')
    or diag "got: $r12";

# Labels and keyword-only statements retain their terminators.
my $r13 = minify('sub f { LABEL:; next; }');
like($r13, qr/LABEL:;next;/, 'labels and keyword-only statements are preserved');

# Opting out preserves semicolons.
my $r14 = minify('sub f { return 1; }', { strip_semicolons => 0 });
like($r14, qr/return\s+1;/, 'semicolon stripping can be disabled');

done_testing;
