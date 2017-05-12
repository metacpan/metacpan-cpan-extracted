# -*- mode: cperl; -*-
# ------ basic require/use testing

use utf8;
use autodie;
use strict;
use warnings;
use lib 'lib';
use Test::Most tests => 2;
use Set::Jaccard::SimilarityCoefficient;

require_ok('Set::Jaccard::SimilarityCoefficient');
use_ok('Set::Jaccard::SimilarityCoefficient');
