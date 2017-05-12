### -*- mode: perl; -*-

use PDF::FDF::Simple;
use Test::More;

use Data::Dumper;
use Parse::RecDescent;
use strict;
use warnings;

plan tests => 4;

################## tests ##################

# Yet another real world file with xref entries
my $fdf_fname = 't/strange_id_values.fdf';


my $fdf = new PDF::FDF::Simple ({ filename => $fdf_fname });
my $res = $fdf->load;

is (
    $res->{'datClientNameDisplay'},
    'Foobar Group',
    "parse"
   );

is (
    $fdf->attribute_file,
    '/C/Documents and Settings/abc/My Documents/Adobe1.pdf',
    "attribute_file"
   );

ok (
    (grep '(P\306p\363%\257\215@\201\344\231\2142\340M\260)', @{$fdf->attribute_id}),
    "attribute_id 1"
   );

ok (
    (grep '(S\366{?X\2349H\206h\334\276s\244\016\()', @{$fdf->attribute_id}),
    "attribute_id 2"
   );

