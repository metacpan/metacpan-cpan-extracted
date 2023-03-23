#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use utf8;
use Test2::V0;
use Test::Script;

for my $p ('storage2dot', 'storage-merge-dots') {
    my $s = 'bin/'.$p;
    script_compiles($s, $p.' compiles');
    script_runs([$s, '--help'], $p.' has help');
    script_runs([$s, '--man'],  $p.' has a manpage');
}

done_testing;   # reached the end safely

