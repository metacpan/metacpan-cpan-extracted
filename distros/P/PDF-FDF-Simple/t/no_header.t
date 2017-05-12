### -*- mode: perl; -*-

use PDF::FDF::Simple;
use Test::More;

use Data::Dumper;
use Parse::RecDescent;
use strict;
use warnings;

plan tests => 4;

################## tests ##################

my $fdf_fname = 't/hunde_no_header.fdf';
my $fdf = new PDF::FDF::Simple ({
                                 'filename' => $fdf_fname,
                                });
my $erg = $fdf->load;

ok (($erg->{'Zu- und Vorname'} eq 'Steffen Schwigon' and
     $erg->{'PLZ'} eq '01159' and
     $erg->{'Anschrift Behörde'} eq "Hundeanstalt\rGroßraum DD"),
    "parse");

ok (($fdf->attribute_file eq 'hundev1.pdf'),
    "attribute_file");

ok ((grep '<ece53a3b05e57db38ed6f01c29a13ced>', @{$fdf->attribute_id}),
    "attribute_id 1");

ok ((grep '<54034b0e4698f348e8b2a91d70e5736b>', @{$fdf->attribute_id}),
    "attribute_id 2");

