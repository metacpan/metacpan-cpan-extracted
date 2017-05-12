#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempdir /;
use File::Spec;
my $tempdir = tempdir (CLEANUP => 1);

use_ok ('Panotools::Script');

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin-optimise.txt');

{
my $tempfile = File::Spec->catfile ($tempdir, '011.txt');
ok ($p->Write ($tempfile), "script written to $tempfile");
}

# set projection to Mercator
#$p->Panorama->{f} = '5';

