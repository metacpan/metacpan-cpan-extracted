#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify);

# 1. Basic rename
my $r1 = minify('my $variable; $variable++;', { shorten_vars => 1 });
ok(defined($r1), 'basic rename returns defined');
ok($r1 !~ /\$variable/, 'basic: $variable renamed') or diag "got: $r1";
ok($r1 =~ /\$c/, 'basic: $variable -> $c') or diag "got: $r1";

# 2. $a and $b in sort blocks are NOT renamed
my $r2 = minify('sort { $a <=> $b } @list', { shorten_vars => 1 });
ok(defined($r2), 'sort block returns defined');
ok($r2 =~ /\$a/, '$a preserved in sort block') or diag "got: $r2";
ok($r2 =~ /\$b/, '$b preserved in sort block') or diag "got: $r2";

# 3. Global per-document map: same name in different scope -> same short name
my $r3 = minify('sub a { my $x = 1; } sub b { my $x = 2; }', { shorten_vars => 1 });
ok(defined($r3), 'global map returns defined');
ok($r3 =~ /\$c.*\$c/s, 'two $x both map to $c') or diag "got: $r3";

# 4. Cross-sigil: %hash -> $hash{foo}
my $r4 = minify('my %hash; $hash{foo} = 1;', { shorten_vars => 1 });
ok(defined($r4), 'cross-sigil returns defined');
ok($r4 =~ /my\s*%c/, '%hash -> %c') or diag "got: $r4";
ok($r4 =~ /\$c\{foo\}/, '$hash{foo} -> $c{foo}') or diag "got: $r4";

# 5. Variable in double-quoted string IS renamed (interpolation support)
my $r5 = minify('my $var; print "$var"', { shorten_vars => 1 });
ok(defined($r5), 'interpolation rename returns defined');
ok($r5 =~ /\$c/, '$var renamed to $c in interpolation') or diag "got: $r5";
ok($r5 =~ /print"\$c"/, 'interpolated string updated correctly') or diag "got: $r5";

# 6. Variable in s/// IS renamed (interpolation support)
my $r6 = minify('my $var; s/foo/$var/', { shorten_vars => 1 });
ok(defined($r6), 's/// rename returns defined');
ok($r6 =~ /\$c/, '$var renamed to $c in s///') or diag "got: $r6";
ok($r6 =~ /s\/foo\/\$c\//, 's/// replacement updated correctly') or diag "got: $r6";

# 7. Hash variable in s///e replacement (the color_map bug)
my $r7 = minify('state %color_map = (a => 1); $s =~ s|x|$color_map{y}|eg;', { shorten_vars => 1 });
ok(defined($r7), 's///e with hash returns defined');
ok($r7 =~ /state%c=/, '%color_map renamed to %c') or diag "got: $r7";
ok($r7 =~ /\$c\{y\}/, '$color_map{y} renamed to $c{y} in s///e') or diag "got: $r7";



# 8. for my $x declaration with normal spacing (strip_whitespace => 0)
my $r8 = minify('for my $item (1..3) { print $item; }', { shorten_vars => 1, strip_whitespace => 0 });
ok(defined($r8), 'for my with spacing returns defined') or diag "got: " . ($r8 // 'undef');
ok($r8 =~ /for\s+my\s+\$c/, 'declared var in for-my renamed') or diag "got: $r8";
ok($r8 =~ /print\s+\$c/, 'usage in for-my body renamed') or diag "got: $r8";

my $r9 = minify('for my $item (1..3) { print $item; }', { shorten_vars => 1 });
ok(defined($r9), 'for my default opts returns defined') or diag "got: " . ($r9 // 'undef');
ok($r9 =~ /my\$c/ && $r9 =~ /print\$c/, 'for-my rename with default strip') or diag "got: $r9";


done_testing;
