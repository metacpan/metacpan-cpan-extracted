#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
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
