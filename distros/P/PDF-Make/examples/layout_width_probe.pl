#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use PDF::Make::Builder;
use PDF::Make::Builder::Font;

my $out = 'corpus/layout_width_probe';

my $pdf = PDF::Make::Builder->new(
    file_name => $out,
    configure => {
        h1   => { font => { colour => '#1f2937', size => 22, line_height => 26 } },
        h2   => { font => { colour => '#334155', size => 14, line_height => 18 } },
        text => { font => { family => 'Helvetica', size => 10, colour => '#111827' } },
    },
);

$pdf->title('Width Probe')
    ->author('PDF::Make');

$pdf->add_page(page_size => 'Letter', padding => 36)
    ->add_h1(text => 'Text Width Probe')
    ->add_text(text => 'Each black bar is a fixed width in points. The Courier line below '
                     . 'is generated so measured text width matches the bar width.')
    ->add_h2(text => 'Courier exact-width rows (10pt)');

my $f_courier = PDF::Make::Builder::Font->new(family => 'Courier', size => 10);
my $char_w = $f_courier->measure_text('X');
my $space_w = $f_courier->measure_text(' ');

my @widths = (120, 180, 240, 300, 360);

for my $w (@widths) {
    my $n = int($w / $char_w);
    $n = 1 if $n < 1;
    my $txt = 'X' x $n;
    my $measured = $f_courier->measure_text($txt);

    $pdf->add_box(fill_colour => '#111827', w => $w, h => 1)
        ->add_text(
            text => sprintf('W=%dpt | chars=%d | measured=%.3fpt | delta=%.3fpt', $w, $n, $measured, $w - $measured),
            font => { family => 'Helvetica', size => 9, colour => '#475569' },
            margin => 2,
        )
        ->add_text(
            text => $txt,
            font => { family => 'Courier', size => 10, colour => '#0f172a' },
            margin => 10,
        );
}

$pdf->add_h2(text => 'Courier rows with spaces (10pt)')
    ->add_text(text => 'Same fixed-width bars, but text is generated as "X X X ..." '
                     . 'to include explicit inter-word spaces.');

for my $w (@widths) {
    my $n = int(($w + $space_w) / ($char_w + $space_w));
    $n = 1 if $n < 1;
    my $txt = join(' ', ('X') x $n);
    my $measured = $f_courier->measure_text($txt);

    $pdf->add_box(fill_colour => '#111827', w => $w, h => 1)
        ->add_text(
            text => sprintf('W=%dpt | tokens=%d | measured=%.3fpt | delta=%.3fpt', $w, $n, $measured, $w - $measured),
            font => { family => 'Helvetica', size => 9, colour => '#475569' },
            margin => 2,
        )
        ->add_text(
            text => $txt,
            font => { family => 'Courier', size => 10, colour => '#0f172a' },
            margin => 10,
        );
}

$pdf->add_h2(text => 'Reference bar + sentence (Helvetica 9pt)')
    ->add_text(text => 'Use this to visually compare glyph ink edge vs advance width endpoint.');

my $ref = 'The center column has weight 2, so it takes twice the width of each';
my $f_helv = PDF::Make::Builder::Font->new(family => 'Helvetica', size => 9);
my $ref_w = $f_helv->measure_text($ref);

$pdf->add_box(fill_colour => '#dc2626', w => $ref_w, h => 1)
    ->add_text(text => sprintf('Helvetica 9pt measured width: %.3fpt', $ref_w),
               font => { family => 'Helvetica', size => 9, colour => '#475569' },
               margin => 2)
    ->add_text(text => $ref,
               font => { family => 'Helvetica', size => 9, colour => '#111827' },
               margin => 8);

$pdf->save;

print "Wrote ${out}.pdf\n";
print "Courier X width at 10pt: ${char_w}pt\n";
print "Courier space width at 10pt: ${space_w}pt\n";
