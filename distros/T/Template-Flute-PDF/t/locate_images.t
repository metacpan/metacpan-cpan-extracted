#! perl

use strict;
use warnings;

use Test::More;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

my ($spec, @tests, $flute, $flute_pdf, $pdf, $cam, @html_files);

$spec = q{<specification></specification>};

@tests = ({template_file => 't/files/sample.html'},
          {template_file => 't/files/html_base.html',
          html_base => 't/files/images'},
         );

plan tests => 2 * @tests;

for my $parms (@tests) {
    $flute = Template::Flute->new(%$parms,
                                  specification => $spec,
        );

    $flute->process();

    $flute_pdf = Template::Flute::PDF->new(template => $flute->template(),
                                           html_base => $parms->{html_base});

    $pdf = $flute_pdf->process();

    $cam = CAM::PDF->new($pdf);

    # check whether we got a valid PDF file
    isa_ok($cam, 'CAM::PDF');

    # locate images
    my ($ctree, $gs, @nodes);

    $ctree = $cam->getPageContentTree(1);
    $gs = $ctree->findImages();
    @nodes = @{$gs->{images}};

    ok(scalar(@nodes) == 1);
};
