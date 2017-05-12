### -*- mode: perl; -*-

use PDF::FDF::Simple;
use Test::More;

use Parse::RecDescent;
use strict;
use warnings;

plan tests => 5;

################## tests ##################

my $fdf_fname = 't/acro8example.fdf';
my $fdf = new PDF::FDF::Simple ({
                                 'filename' => $fdf_fname,
                                });
my $erg = $fdf->load;

ok ((
    $erg->{'Q1.a'} eq '2' and
    $erg->{'Q1.b'} eq '3' and
    $erg->{'Q1.c'} eq '2' and
    $erg->{'Q1.d'} eq 'Yes'
    ),
    "parse");

ok (($fdf->attribute_file eq '/atlas/home/wef/IssuesMapping/Surveys/ME002.pdf'),
    "attribute_file");

ok (($fdf->attribute_ufile eq '/atlas/home/wef/IssuesMapping/Surveys/ME002.pdf'),
    "attribute_ufile");

ok ((grep '<144F6E41F6052003A794A6A1376FD1A5>', @{$fdf->attribute_id}),
    "attribute_id 1");

ok ((grep '<FE32DB6C5FD3994ABF65CAB1AB93E927>', @{$fdf->attribute_id}),
    "attribute_id 2");

