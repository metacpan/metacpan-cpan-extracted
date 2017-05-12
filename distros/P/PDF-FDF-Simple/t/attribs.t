### -*- mode: perl; -*-

use Test::More;

use PDF::FDF::Simple;
use File::Temp qw( tempfile );

use Data::Dumper;
use Parse::RecDescent;
use strict;
use warnings;

plan tests => 5;

################## tests ##################


my $fdf_fname = 't/hundev1.fdf';
my $fdf = new PDF::FDF::Simple ({
                                 'filename' => $fdf_fname,
                                });
my $erg = $fdf->load;

ok (($erg->{'Zu- und Vorname'} eq 'Steffen Schwigon' and
     $erg->{'PLZ'} eq '01159' and
     $erg->{'Anschrift Behörde'} eq "Hundeanstalt\rGroßraum DD"),
    "parse");

is ($fdf->attribute_file,
    'hundev1.pdf',
    "attribute_file");

is ($fdf->attribute_ufile,
    '/atlas/home/wef/IssuesMapping/Surveys/ME002.pdf',
    "attribute_ufile");

ok ((grep '<ece53a3b05e57db38ed6f01c29a13ced>', @{$fdf->attribute_id}),
    "attribute_id 1");

ok ((grep '<54034b0e4698f348e8b2a91d70e5736b>', @{$fdf->attribute_id}),
    "attribute_id 2");

