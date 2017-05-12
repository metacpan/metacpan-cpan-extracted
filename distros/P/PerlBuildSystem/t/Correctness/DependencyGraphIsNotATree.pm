#!/usr/bin/env perl

# Tests for correctness in building, that is files are rebuilt when
# they should, and not rebuilt when they should not.
# These tests all have dependency graph that is not a tree.

package t::Correctness::DependencyGraphIsNotATree;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Dependency graph is not a tree');

    $t->build_dir('build_dir');
    $t->target('test-c' . $t::PBS::_exe);

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node ( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

sub three_c_files_one_include_file : Test(8) {
    # Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => '1.o', '2.o', '3.o' ] =>
        '%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_
    $t->write('1.c', <<'_EOF_');
    #include <stdio.h>
    void f_a(void);
    int main(int argc, char *argv[]) {
        f_a();
        printf("1.c\n");
        return 0;
    }
_EOF_
    $t->write('2.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc.h"
    void f_a(void);
    void f_b(void);
    void f_a(void) {
        f_b();
        printf(INC_STRING);
        printf("2.c\n");
    }
_EOF_
    $t->write('3.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc.h"
    void f_b(void);
    void f_b(void) {
        printf(INC_STRING);
        printf("3.c\n");
    }
_EOF_
    $t->write('inc.h', <<'_EOF_');
    #define INC_STRING "inc\n"
_EOF_

    # Build
    $t->build_test;
    $t->run_target_test(stdout => "inc\n3.c\ninc\n2.c\n1.c\n");

    $t->test_up_to_date;

	# Modify the include file and rebuild
    $t->write('inc.h', <<'_EOF_');
    #define INC_STRING "inc2\n"
_EOF_

    $t->build_test;
    $t->run_target_test(stdout => "inc2\n3.c\ninc2\n2.c\n1.c\n");

    $t->test_up_to_date;
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
