#! perl -T

use strict;
use warnings;

use Template::Flute;
use Template::Flute::PDF;

use CAM::PDF;

use Test::More;

my ($spec, $html, $flute, $flute_pdf, $pdf, $cam, @images);

@images = qw/sample.jpg/;

eval "use Image::Magick";

unless ($@) {
    push (@images, 'sample.bmp');
}

plan tests => 2 * @images;

$spec = q{<specification></specification>};

for my $pic (@images) {
    $html = qq{<img src="t/files/$pic">};

    $flute = Template::Flute->new(template => $html,
                                  specification => $spec,
        );

    $flute->process();

    $flute_pdf = Template::Flute::PDF->new(template => $flute->template());

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
}
