#!perl
# A SOURCE CHECK, because the bug it names is invisible at runtime here.
#
# Before 5.32 SvTRUE, SvIV, SvUV, SvNV and SvPV mention their argument more
# than once, so SvTRUE(POPs) pops once per mention: the value is read from
# whatever sits below the one that was returned, and the walk off the stack
# base is a SEGV on a debugging perl. As of 5.32 they evaluate once, so a
# modern perl runs the same line correctly and no runtime test can fail on it.
# Only reading the source catches it, on every perl including this one.
#
# The fix is always the same shape: pop into a variable, then test that.
use 5.010;
use strict;
use warnings;
use Test::More;

# The headers carry most of the C, so they are read too, not just the XS.
my @src = grep { -f } ('Observe.xs', glob('xs/*.xs'),
                       glob('include/punk_observe/*.h'));
plan skip_all => 'XS sources are not in this tree' unless @src;

# SvTRUE was fixed in 5.32, SvIV/SvUV/SvNV only in 5.37.1. SvOK, SvROK and
# SvTYPE are single-mention and are deliberately not here. TOPs is (*sp) and
# has no side effect, so this guard deliberately does not flag it.
my $MULTI = qr/\bSv(?:TRUE(?:_nomg)?|IV|UV|NV|PV(?:byte|utf8)?(?:_nolen)?)\s*\(/;

my $checked = 0;
for my $file (@src) {
    open my $fh, '<', $file or die "$file: $!";
    my $src = do { local $/; <$fh> };
    close $fh;
    $checked++;

    # Blank out comments and literals, keeping every newline so the line
    # numbers still name the code. Without this the guard reports the prose
    # explaining the trap as an instance of it.
    $src =~ s{
        ( " (?: \\. | [^"\\]  )*  "      )   # a string
      | ( ' (?: \\. | [^'\\\n] )   '      )   # a character
      | ( /\* .*? \*/                     )   # a block comment
      | ( // [^\n]*                       )   # a line comment
    }{ my $t = $&; $t =~ s/[^\n]/ /g; $t }gsex;

    my @bad;
    while ($src =~ /$MULTI/g) {
        my $open = pos($src) - 1;      # the '(' the macro name ended on
        my ($depth, $i) = (0, $open);
        my $len = length $src;
        # Walk to the matching close paren so the argument is the whole
        # argument, not whatever fitted on one line.
        while ($i < $len) {
            my $c = substr($src, $i, 1);
            $depth++ if $c eq '(';
            if ($c eq ')') { $depth--; last if $depth == 0 }
            $i++;
        }
        my $arg = substr($src, $open + 1, $i - $open - 1);
        next unless $arg =~ /\bPOP[a-z]?\b/;
        my $line = 1 + (() = substr($src, 0, $open) =~ /\n/g);
        push @bad, "$file:$line: " . join(' ', split ' ', $arg);
    }

    is(scalar @bad, 0, "$file pops before it converts")
        or diag("a multi-eval Sv macro pops the stack once per mention:\n  "
                . join("\n  ", @bad));
}

cmp_ok($checked, '>', 1, 'more than one source was read');

done_testing;
