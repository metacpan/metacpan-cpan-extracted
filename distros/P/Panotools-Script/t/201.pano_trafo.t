#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Script;

my $pto = new Panotools::Script;

unless (`pano_trafo`)
{
    print STDERR "pano_trafo not found, skipping tests...\n";
    ok(1);
    exit;
}

$pto->InitTrafo ('t/data/cemetery/hugin.pto');

like (join (', ', $pto->TrafoReverse (0, $pto->Trafo (0, 0, 0))), '/^0\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (0, $pto->Trafo (0, 1, 0))), '/^1\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (0, $pto->Trafo (0, 2, 0))), '/^2\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (0, $pto->Trafo (0, 3, 0))), '/^3\.0.*, 0\.0/');

like (join (', ', $pto->TrafoReverse (1, $pto->Trafo (1, 0, 0))), '/^0\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (1, $pto->Trafo (1, 1, 0))), '/^1\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (1, $pto->Trafo (1, 2, 0))), '/^2\.0.*, 0\.0/');
like (join (', ', $pto->TrafoReverse (1, $pto->Trafo (1, 3, 0))), '/^3\.0.*, 0\.0/');


