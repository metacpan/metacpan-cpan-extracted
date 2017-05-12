#!/usr/bin/env perl

# Tests for correctness in a C dependency graph.
#
# This test was written because there was a bug that made the C
# dependencie cache incorrect. This test catches that bug.

package t::Misc::CDependencyGraph;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'C dependency graph');

    $t->build_dir('build_dir');
    $t->target('test_c' . $t::PBS::_exe);

    # A post-pbs that prints the dependencies for ./main.c
    $t->write('post_pbs.pl', <<'_EOF_');
    for my $key(keys %$inserted_nodes) {
        print "$key\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

my $file_pbsfile1 = <<"_EOF_";
PbsUse('Configs/Compilers/gcc');
PbsUse('Rules/C');

AddRule 'test_c', [ 'test_c$t::PBS::_exe' => 'main.o' ] =>
    '%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_

my $file_main1_c = <<'_EOF_';
#include <stdio.h>
#include "inc.h"
int main(int argc, char *argv[]) {
    printf(INC_STRING);
    return 0;
}
_EOF_

my $file_inc_a_h = <<'_EOF_';
#define INC_STRING "inc_a.h\n"
_EOF_

sub c_dependency_graph : Test(5) {
# Write files
    $t->write_pbsfile($file_pbsfile1);
    $t->write('main.c', $file_main1_c);
    $t->write('inc.h', $file_inc_a_h);

# Build
    $t->build_test;
    my $stdout = $t->stdout;
    like($stdout, qr|inc\.h|, 'Include file is in dependency graph');
    $t->test_up_to_date;
    $stdout = $t->stdout;
    #~ $t->generate_test_snapshot_and_exit();

# The bug was here. The cache didn't include the dependency inc.h
    like($stdout, qr|inc\.h|, 'Include file is in dependency graph');
    #~ $t->generate_test_snapshot_and_exit();
}


unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
