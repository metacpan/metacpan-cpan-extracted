#!/usr/bin/env perl
# Cross-verify the library's Pronto output against a reference MakeHex build.
#
# MakeHex (https://github.com/probonopd/MakeHex) is the generator IRDB's
# README points to, so its Pronto is the ground truth for IRDB rows. This
# script encodes the same device/subdevice/function through MakeHex and the
# library and compares carrier word, pair count, header, wire bitstream, and
# stop pulse for the whole NEC family and JVC.
#
# Usage:
#   git clone https://github.com/probonopd/MakeHex.git /tmp/makehex
#   cd /tmp/makehex && make
#   perl tools/verify_pronto.pl
#
# Set MAKEHEX_DIR to override the MakeHex location. Requires the built
# binary at $MAKEHEX_DIR/makehex and IRP files in $MAKEHEX_DIR/protocols.
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Protocol::IR::Converter;

my $MAKEHEX_DIR = $ENV{MAKEHEX_DIR} // "/tmp/makehex";
my $MAKEHEX     = "$MAKEHEX_DIR/makehex";
my $IRP_DIR     = "$MAKEHEX_DIR/protocols";
die "MakeHex not built at $MAKEHEX (set MAKEHEX_DIR)\n" unless -x $MAKEHEX;
die "IRP files not found at $IRP_DIR\n" unless -d $IRP_DIR;

my $converter = Protocol::IR::Converter->new();

my @fail;
my $total = 0;

# variant => [irp file, list of [device, subdevice], function list]
my %cases = (
    'NEC'   => ['nec1.irp',  [[4, -1], [4, 0], [25, -1], [16, 0xEF]]],
    'NEC2'  => ['nec2.irp',  [[26, 232], [186, -1], [79, 80]]],
    'NECX1' => ['NECx1.irp', [[162, 162], [7, 7], [11, 11], [16, 0xEF]]],
    'NECX2' => ['NECx2.irp', [[7, 7], [5, 5], [7, -1]]],
    'JVC'   => ['jvc.irp',   [[131, -1], [3, -1], [83, -1]]],
);
my @functions = (1, 2, 8, 64, 0xFF);

sub makehex_pronto {
    my ($irp, $dev, $sub, $func) = @_;
    my $device = ($sub >= 0) ? "$dev.$sub" : $dev;
    open my $in, '<', "$IRP_DIR/$irp" or die "open $irp: $!";
    my $text = do { local $/; <$in> };
    close $in;
    $text =~ s/^Device=.*/Device=$device/m;
    $text =~ s/^Function=.*/Function=$func..$func/m;
    open my $out, '>', "$MAKEHEX_DIR/verify.irp" or die $!;
    print {$out} $text;
    close $out;
    system("$MAKEHEX $MAKEHEX_DIR/verify.irp $MAKEHEX_DIR/verify.out 2>/dev/null") == 0
        or die "makehex failed";
    open my $f, '<', "$MAKEHEX_DIR/verify.out" or die $!;
    my ($want_fn, $pronto);
    while (<$f>) {
        $want_fn = $1 if /Function: (\d+)/;
        $pronto  = $_  if /^0000/;
    }
    close $f;
    die "makehex no output for fn=$func" unless defined $pronto && $want_fn == $func;
    $pronto =~ s/^\s+|\s+$//g;
    return $pronto;
}

# Turn a Pronto string into an arrayref of [mark_us, space_us] pairs.
sub pronto_to_pairs {
    my ($pronto) = @_;
    my @t = split /\s+/, $pronto;
    my $carrier = int(1000000.0 / (hex($t[1]) * 0.241246));
    my $period  = 1000000.0 / $carrier;
    my $npairs  = hex($t[2]) + hex($t[3]);
    my @pairs;
    for (my $i = 0; $i < $npairs; $i++) {
        push @pairs, [hex($t[4 + 2*$i]) * $period, hex($t[5 + 2*$i]) * $period];
    }
    return \@pairs;
}

sub wire_bits {
    my ($pairs, $nbits) = @_;
    my @bits;
    for my $i (1 .. $nbits) { push @bits, ($pairs->[$i][1] > 1000) ? 1 : 0 }
    return join '', @bits;
}

sub check {
    my ($label, $ok, $detail) = @_;
    $total++;
    if ($ok) { print "  ok   $label\n" }
    else {
        push @fail, $label;
        print "  FAIL $label: $detail\n";
    }
}

for my $proto (sort keys %cases) {
    my ($irp, $combos) = @{$cases{$proto}};
    print "== $proto (irp $irp) ==\n";
    for my $fn (@functions) {
        for my $c (@$combos) {
            my ($dev, $sub) = @$c;
            my $label = "$proto dev=$dev sub=$sub fn=$fn";
            next if $proto eq 'JVC' && $sub != -1; # JVC has no subdevice

            my $ref_pronto = makehex_pronto($irp, $dev, $sub, $fn);
            my $ref_pairs = pronto_to_pairs($ref_pronto);

            my $code = $converter->import_code($proto,
                { device => $dev, subdevice => $sub, command => $fn });
            my $our_pronto = $converter->export_code($code, 'Pronto');
            my $our_pairs = pronto_to_pairs($our_pronto);

            my @ref_words = split /\s+/, $ref_pronto;
            my @our_words = split /\s+/, $our_pronto;

            # nec1.irp / NECx1.irp append a repeat frame (Form=...;*,_) after
            # the primary frame; the library emits only the primary data frame
            # (repetition is the transmitter's job). Compare against MakeHex's
            # primary data frame (first 34 pairs).
            if ($proto =~ /^NEC/ && @$ref_pairs > 34) {
                my @primary = @{$ref_pairs}[0 .. 33];
                $ref_pairs = \@primary;
            }

            check("$label: freq word", $our_words[1] eq $ref_words[1],
                "ours $our_words[1] ref $ref_words[1]");
            check("$label: pair count",
                scalar(@$our_pairs) == scalar(@$ref_pairs),
                "ours " . scalar(@$our_pairs) . " ref " . scalar(@$ref_pairs));
            check("$label: header mark",
                abs($our_pairs->[0][0] - $ref_pairs->[0][0]) < 150,
                sprintf("ours %.0f ref %.0f", $our_pairs->[0][0], $ref_pairs->[0][0]));
            check("$label: header space",
                abs($our_pairs->[0][1] - $ref_pairs->[0][1]) < 150,
                sprintf("ours %.0f ref %.0f", $our_pairs->[0][1], $ref_pairs->[0][1]));
            my $nbits = ($proto eq 'JVC') ? 16 : 32;
            check("$label: wire bits",
                wire_bits($our_pairs, $nbits) eq wire_bits($ref_pairs, $nbits),
                wire_bits($our_pairs, $nbits) . " vs " . wire_bits($ref_pairs, $nbits));
            check("$label: stop mark",
                abs($our_pairs->[-1][0] - $ref_pairs->[-1][0]) < 150,
                sprintf("ours %.0f ref %.0f", $our_pairs->[-1][0], $ref_pairs->[-1][0]));
        }
    }
}

print "\n$total checks, ", scalar(@fail), " failures\n";
exit(@fail ? 1 : 0);
