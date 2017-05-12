#! /usr/bin/env perl

use strict;
use warnings;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

use Test::More tests => 2;

my ($spec, $html, $flute, $flute_pdf, $pdf, $cam);

$html = q{<i>Test</i>};
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

my @fonts = $cam->getFontNames(1);

ok(@fonts == 2, 'Number of fonts used for document with <i> tag.')
    || diag('Fonts used: ', join(', ', @fonts));
