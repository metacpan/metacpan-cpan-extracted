#!perl -T
use strict;
use warnings FATAL => 'all';
use PostScript::Barcode qw();
use Test::Exception tests => 1;

dies_ok {PostScript::Barcode->new(data => 0);};
