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
my $fdf_fname = 't/with_xrefs_and_valuearrays.fdf';


my $fdf = new PDF::FDF::Simple ({ filename => $fdf_fname });
my $res = $fdf->load;

is (
    $res->{'AgenciesContacted'},
    'ACME - Some Corporation',
    "parse"
   );

is (
    $fdf->attribute_file,
    'file:///Users/lcsuser/Desktop/Test/LD2Q.pdf',
    "attribute_file"
   );

ok (
    (grep '(P\306p\363%\257\215@\201\344\231\2142\340M\260)', @{$fdf->attribute_id}),
    "attribute_id 1"
   );

ok (
    (grep '(\320?\027\016B\325E\226\251\007G\n\347\324\374\237)', @{$fdf->attribute_id}),
    "attribute_id 2"
   );

