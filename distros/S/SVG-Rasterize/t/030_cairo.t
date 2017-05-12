#!perl -T
use strict;
use warnings;

use Test::More tests => 1;

use Test::Exception;
use SVG::Rasterize;
use SVG::Rasterize::Regexes qw(:all);

use_ok('SVG::Rasterize::Engine::PangoCairo');
