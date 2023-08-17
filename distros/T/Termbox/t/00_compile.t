use strict;
use warnings;
use Test::More 0.98;
use lib '../lib', 'lib';
#
use_ok $_ for qw[Termbox];
diag 'libtermbox2 v' . Termbox::tb_version();
#
done_testing;
