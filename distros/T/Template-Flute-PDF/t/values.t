#! /usr/bin/env perl
#
# Basic text tests.

use strict;
use warnings;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

use Test::More;

my (@values, $spec, $html, $flute, $flute_pdf, $pdf, $cam, $text);

$spec = q{<specification>
<value name="test"/>
</specification>
};

$html = q{<div class="test">TEST</div>};

@values = (0, 1, 'test');

plan tests => @values * 2;

for my $value (@values) {
    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
                                  values => {test => $value},
    );

    $flute->process();

    $flute_pdf = Template::Flute::PDF->new(template => $flute->template());

    $pdf = $flute_pdf->process();

    $cam = CAM::PDF->new($pdf);

    # check whether we got a valid PDF file
    isa_ok($cam, 'CAM::PDF');

    $text = $cam->getPageText(1);

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    
    ok ($text eq $value, "basic value test with: $value")
        || diag qq{Text is "$text" instead of $value.};
}

