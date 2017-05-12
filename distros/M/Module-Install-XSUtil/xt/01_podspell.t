#!perl -w

use strict;
use Test::More;
use Test::Spellunker v0.2.1;

load_dictionary(\*DATA);
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji (gfx)
gfuji(at)cpan.org
Module::Install::XSUtil
Nishino
lestrrat
ACKNOWLEDGEMENT
XS
RT
co
realclean
