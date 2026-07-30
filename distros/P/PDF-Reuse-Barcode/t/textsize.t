#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    use_ok('PDF::Reuse')           or BAIL_OUT "Can't load PDF::Reuse";
    use_ok('PDF::Reuse::Barcode')  or BAIL_OUT "Can't load PDF::Reuse::Barcode";
}

my $dir = tempdir(CLEANUP => 1);

# Returns the content stream operators for a barcode drawn with the given
# options, with the time-based /ID trailer removed so two runs are comparable.
sub render {
    my (%opt) = @_;
    my $file = File::Spec->catfile($dir, "bc$$" . int(rand 1e6) . '.pdf');
    prInitVars();
    prFile($file);
    PDF::Reuse::Barcode::Code39(x => 50, y => 700, value => '123456789', %opt);
    prEnd();

    open my $fh, '<', $file or BAIL_OUT "can't read $file: $!";
    binmode $fh;
    my $pdf = do { local $/; <$fh> };
    close $fh;
    unlink $file;

    $pdf =~ s{^/ID \[<.*$}{}m;
    return $pdf;
}

# The default must reproduce pre-0.10 output exactly. The old code hardcoded
# prFontSize(10) and a glyph width of 6; textsize derives both, and Courier is
# monospaced at 600/1000 em, so 10 * 0.6 == 6 by construction rather than by
# approximation.
my $default  = render();
my $explicit = render(textsize => 10);
is($default, $explicit,
    'textsize => 10 renders identically to omitting the parameter');

like($default, qr{/Ft1 10 Tf},
    'default text is still 10 point');

my $large = render(textsize => 24);
like($large, qr{/Ft1 24 Tf},
    'textsize => 24 sets the font size');
isnt($large, $default,
    'a non-default textsize changes the output');

# The text is centred on the barcode, so a larger size must start further left.
my ($x_default) = $default =~ m{/Ft1 10 Tf ([-\d.]+) [-\d.]+ Td};
my ($x_large)   = $large   =~ m{/Ft1 24 Tf ([-\d.]+) [-\d.]+ Td};
ok(defined $x_default && defined $x_large && $x_large < $x_default,
    'larger text is re-centred, not left-anchored')
    or diag("default x=" . ($x_default // 'undef') . " large x=" . ($x_large // 'undef'));

# text => '' suppresses the text entirely; textsize must not resurrect it.
my $none = render(text => '', textsize => 24);
unlike($none, qr{/Ft1 \d+ Tf},
    'textsize does not override text => ""');

# Codex review of #5: the overflow background is emitted after general2() has
# already painted the bars, so a full-width rectangle would cover them. Only
# the two side strips may be drawn.
sub render_qr {
    my (%opt) = @_;
    my $file = File::Spec->catfile($dir, "qr$$" . int(rand 1e6) . '.pdf');
    prInitVars();
    prFile($file);
    PDF::Reuse::Barcode::QRcode(x => 100, y => 400, value => 'HELLO', %opt);
    prEnd();
    open my $fh, '<', $file or BAIL_OUT "can't read $file: $!";
    binmode $fh;
    my $pdf = do { local $/; <$fh> };
    close $fh;
    unlink $file;
    return $pdf;
}

my $overflow = render_qr(textsize => 24);
my ($strips) = $overflow =~ m{^(q [\d.]+ g [-\d.]+ 0 [\d.]+ [\d.]+ re f\* [-\d.]+ 0 [\d.]+ [\d.]+ re f\* Q)$}m;
ok($strips, 'overflowing text emits side background strips')
    or diag("no strip operator found");

SKIP: {
    skip 'no strips emitted', 2 unless $strips;
    my ($x1, $w1, $x2) = $strips =~ m{([-\d.]+) 0 ([\d.]+) [\d.]+ re f\* ([-\d.]+) 0};
    # The left strip must end at 0 and the right strip must start at the box
    # edge, so neither covers the span the barcode occupies.
    cmp_ok($x1 + $w1, '<=', 0.001,
        'left strip stops at the barcode edge, does not cover it');
    cmp_ok($x2, '>=', 0,
        'right strip starts at or beyond the barcode edge');
}

# drawbackground => 0 must stay honoured on the overflow path.
my $nobg = render_qr(textsize => 24, drawbackground => 0);
unlike($nobg, qr{re f\* [-\d.]+ 0 [\d.]+ [\d.]+ re f\*},
    'drawbackground => 0 suppresses the overflow strips');

# GitHub #8: the text baseline is fixed at 1.5 while bars start at 9, so the
# clearance was sized for the old hard-coded 10 point. Above roughly 12pt the
# digits printed into the bar region -- a scannability failure. The bars are
# now lifted by the extra digit height so the clearance is preserved.
sub geometry {
    my (%opt) = @_;
    my $pdf = render(%opt);
    my @bottoms;
    while ($pdf =~ /[\d.]+ [\d.]+ m\n [\d.]+ ([\d.]+) l/g) { push @bottoms, $1 }
    my ($size, $baseline) = $pdf =~ m{/Ft1 ([\d.]+) Tf [-\d.]+ ([-\d.]+) Td};
    my ($box_h) = $pdf =~ m{0 0 [\d.]+ ([\d.]+) re};
    return unless @bottoms && defined $size;
    my ($lowest) = sort { $a <=> $b } @bottoms;
    # 0.622 em is the Courier digit bbox height above the baseline.
    return { top => $baseline + 0.622 * $size, bar => $lowest, box => $box_h };
}

my $g10 = geometry();
my $g20 = geometry(textsize => 20);
ok($g10 && $g20, 'geometry extracted for both sizes') or diag('regex did not match');

SKIP: {
    skip 'geometry not extractable', 4 unless $g10 && $g20;

    cmp_ok($g10->{top}, '<', $g10->{bar},
        'GitHub #8: digits clear the bars at the default size');
    cmp_ok($g20->{top}, '<', $g20->{bar},
        'GitHub #8: digits clear the bars at 20 point');

    # Clearance must not shrink as the text grows -- that is what distinguishes
    # lifting the bars from getting lucky on a threshold. The lift is sized on
    # the tallest glyph any value can contain (0.75 em), so a digits-only value
    # measured at 0.622 em gains headroom rather than merely holding station.
    my $c10 = $g10->{bar} - $g10->{top};
    my $c20 = $g20->{bar} - $g20->{top};
    cmp_ok($c20, '>=', $c10 - 0.01,
        'GitHub #8: clearance is preserved, not eroded, at a larger size')
        or diag("default clearance $c10, large clearance $c20");

    # Lifting the bars without growing the box would push them out the top.
    cmp_ok($g20->{box}, '>', $g10->{box},
        'GitHub #8: background box grows with the lift');
}

# GitHub #6: $qrcode was set by QRcode() and never reset, so every later
# barcode in the same process took the QR rendering branch. This surfaced
# while writing the #8 geometry tests above -- they measured QR output
# instead of Code39 because the QR tests earlier in this file ran first.
{
    my $qr = render_qr();
    my @modules = $qr =~ /[\d.]+ [\d.]+ 1 1 re/g;
    ok(scalar @modules > 100,
        'GitHub #6: QRcode still draws its modules')
        or diag('module rects: ' . scalar @modules);

    # A linear barcode after a QRcode must use the linear text placement
    # (baseline 1.5), not the QR quiet-zone placement (a negative offset).
    my $after = render();
    my ($baseline) = $after =~ m{/Ft1 [\d.]+ Tf [-\d.]+ ([-\d.]+) Td};
    is($baseline, '1.5',
        'GitHub #6: Code39 after a QRcode uses the linear text placement');

    my @bars = $after =~ /[\d.]+ [\d.]+ m\n [\d.]+ ([\d.]+) l/g;
    ok(scalar @bars > 0,
        'GitHub #6: Code39 after a QRcode still draws bars');
}

# Codex review of #9: the lift was sized on digit height (0.622 em), but
# Code39 accepts $ at 0.662 and Code128 the whole printable ASCII range, where
# | reaches 0.75. A dollar sign overprinted above 32 point.
{
    my $pdf = render(value => 'A$B', textsize => 40);
    my ($size, $baseline) = $pdf =~ m{/Ft1 ([\d.]+) Tf [-\d.]+ ([-\d.]+) Td};
    my @bottoms;
    while ($pdf =~ /[\d.]+ [\d.]+ m\n [\d.]+ ([\d.]+) l/g) { push @bottoms, $1 }
    my ($lowest) = sort { $a <=> $b } @bottoms;

    # 0.662 em is the AFM bbox height of Courier's dollar glyph.
    cmp_ok($baseline + 0.662 * $size, '<=', $lowest,
        'GitHub #9: a dollar sign clears the bars at 40 point')
        or diag("dollar top " . ($baseline + 0.662 * $size) . ", bar bottom $lowest");

    # 0.75 em is the tallest printable-ASCII glyph, which Code128 can carry.
    cmp_ok($baseline + 0.75 * $size, '<=', $lowest + 0.01,
        'GitHub #9: the tallest possible glyph clears the bars at 40 point')
        or diag("tallest top " . ($baseline + 0.75 * $size) . ", bar bottom $lowest");
}
