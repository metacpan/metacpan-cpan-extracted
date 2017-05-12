#! /usr/bin/env perl

use strict;
use warnings;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

use Test::More tests => 2;

my ($spec, $html, $flute, $flute_pdf, $pdf, $cam);
my ($font_count, $font_name, $font_spec, @styles, @divs);

push(@styles, q{div {border: 10pt solid black;}});

while (($font_name, $font_spec) = each %Template::Flute::PDF::font_map) {
    # normal
    push (@styles, ".$font_name {font-family: $font_name;}");
    push (@divs, qq{<h2>$font_name</h2><div class="$font_name">$font_name</div>});
    $font_count++;
    
    if (exists $font_spec->{Italic}) {
        # italic
        push (@styles, ".${font_name}_italic {font-family: $font_name; font-style: italic}");
        push (@divs, qq|<h2>$font_name italic</h2><div class="${font_name}_italic">$font_name</div>|);
        $font_count++;
    }
}

$html = q{<style>} . join("\n", @styles) . q{</style>
} . join("\n", @divs);

$spec = q{<specification></specification>};

$flute = Template::Flute->new(template => $html,
                              specification => $spec,
    );

$flute->process();

$flute_pdf = Template::Flute::PDF->new(template => $flute->template());

$pdf = $flute_pdf->process();

$cam = CAM::PDF->new($pdf);

# check whether we got a valid PDF file
isa_ok($cam, 'CAM::PDF');

# check number of fonts
my @fonts = $cam->getFontNames(1);
ok (@fonts == @styles - 1, 'Test number of fonts');


