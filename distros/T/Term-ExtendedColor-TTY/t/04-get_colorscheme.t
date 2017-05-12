#!/usr/bin/perl
use Test::More tests => 2;

use Term::ExtendedColor::TTY::Colorschemes;


is(ref( get_colorscheme('matrix') ), 'HASH', 'Colorscheme table returned');
ok(scalar( get_colorschemes() ) > 0, 'Colorscheme strings found');
