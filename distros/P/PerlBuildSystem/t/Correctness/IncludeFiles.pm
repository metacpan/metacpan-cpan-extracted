#!/usr/bin/env perl

# Tests for correctness in building, that is files are rebuilt when
# they should, and not rebuilt when they should not.
# These tests all uses programs with include files.

package t::Correctness::IncludeFiles;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Include files');

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

my $file_pbsfile1 = <<"_EOF_";
PbsUse('Configs/Compilers/gcc');
PbsUse('Rules/C');

AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'main.o' ] =>
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

my $file_inc_a2_h = <<'_EOF_';
#define INC_STRING "inc_a2.h\n"
_EOF_

my $file_inc_b_h = <<'_EOF_';
#define INC_STRING "inc_b.h\n"
_EOF_

my $file_inc_b2_h = <<'_EOF_';
#define INC_STRING "inc_b2.h\n"
_EOF_

my $file_inc_a_a_h = <<'_EOF_';
#define INC_STRING_A "inc_a.h\n"
_EOF_

my $file_inc_a_a2_h = <<'_EOF_';
#define INC_STRING_A "inc_a2.h\n"
_EOF_

my $file_inc_b_b_h = <<'_EOF_';
#define INC_STRING_B "inc_b.h\n"
_EOF_

my $file_inc_b_b2_h = <<'_EOF_';
#define INC_STRING_B "inc_b2.h\n"
_EOF_

sub normal_include : Test(8) {
# Write files
    $t->write_pbsfile($file_pbsfile1);
    $t->write('main.c', $file_main1_c);
    $t->write('inc.h', $file_inc_a_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_a.h\n");

    $t->test_up_to_date;

# Modify the include file and rebuild
    $t->write('inc.h', $file_inc_a2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.h\n");

    $t->test_up_to_date;
}

sub include_path : Test(6) {
# Create subdirectory
    $t->subdir('subdir');

# Write files
    $t->write_pbsfile(<<"_EOF_");
    AddConfigTo 'BuiltIn', 'CFLAGS_INCLUDE' =>   " -I subdir";
    
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_

    $t->write('main.c', $file_main1_c);
    $t->write('subdir/inc.h', $file_inc_a_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_a.h\n");

# Modify the include file and rebuild
    $t->write('subdir/inc.h', $file_inc_a2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.h\n");

    $t->test_up_to_date;
}

sub include_path_two_include_files_with_the_same_name : Test(8) {
# Create subdirectories
    $t->subdir('subdir_a', 'subdir_b');

# Write files
    $t->write_pbsfile(<<"_EOF_");
    AddConfigTo 'BuiltIn', 'CFLAGS_INCLUDE' =>   " -I subdir_b"
	                                       . " -I subdir_a" ;
    
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_

    $t->write('main.c', $file_main1_c);
    $t->write('subdir_a/inc.h', $file_inc_a_h);
    $t->write('subdir_b/inc.h', $file_inc_b_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_b.h\n");

# Modify the unused include file and rebuild
    $t->write('subdir_a/inc.h', $file_inc_a2_h);
    $t->test_up_to_date;

# Modify the other include file and rebuild
    $t->write('subdir_b/inc.h', $file_inc_b2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_b2.h\n");

    $t->test_up_to_date;
}

sub two_include_files : Test(10) {
# Write files
    $t->write_pbsfile($file_pbsfile1);
    $t->write('main.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_a.h"
    #include "inc_b.h"
    int main(int argc, char *argv[]) {
	printf(INC_STRING_A);
	printf(INC_STRING_B);
	return 0;
    }
_EOF_

    $t->write('inc_a.h', $file_inc_a_a_h);
    $t->write('inc_b.h', $file_inc_b_b_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_a.h\ninc_b.h\n");

# Modify the first include file and rebuild
    $t->write('inc_a.h', $file_inc_a_a2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.h\ninc_b.h\n");

    $t->test_up_to_date;
    
# Modify the other include file and rebuild
    $t->write('inc_b.h', $file_inc_b_b2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.h\ninc_b2.h\n");

    $t->test_up_to_date;
}

sub two_include_files_one_includes_the_other : Test(10) {
# Write files
    $t->write_pbsfile($file_pbsfile1);
    $t->write('main.c', $file_main1_c);
    $t->write('inc.h', <<'_EOF_');
    #include "inc_b.h"
    #define INC_STRING "inc_a.h" INC_STRING_B
_EOF_
    $t->write('inc_b.h', $file_inc_b_b_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_a.hinc_b.h\n");

# Modify the first include file and rebuild
    $t->write('inc.h', <<'_EOF_');
    #include "inc_b.h"
    #define INC_STRING "inc_a2.h" INC_STRING_B
_EOF_
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.hinc_b.h\n");

    $t->test_up_to_date;
    
# Modify the other include file and rebuild
    $t->write('inc_b.h', $file_inc_b_b2_h);
    $t->build_test;
    $t->run_target_test(stdout => "inc_a2.hinc_b2.h\n");

    $t->test_up_to_date;
}

sub two_c_files_two_include_files : Test(14) {
# Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => '1.o', '2.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_

    $t->write('1.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_a.h"
    void f1(void);
    void f1(void) {
	printf(INC_STRING);
    }
_EOF_

    $t->write('2.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_b.h"
    void f1(void);
    int main(int argc, char *argv[]) {
	f1();
	printf(INC_STRING);
	return 0;
    }
_EOF_

    $t->write('inc_a.h', $file_inc_a_h);
    $t->write('inc_b.h', $file_inc_b_h);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "inc_a.h\ninc_b.h\n");

# Modify the first include file and rebuild
    $t->write('inc_a.h', $file_inc_a2_h);
    $t->build_test;
    $t->test_node_was_rebuilt("./1.c");
    $t->test_node_was_not_rebuilt("./2.c");
    $t->run_target_test(stdout => "inc_a2.h\ninc_b.h\n");

    $t->test_up_to_date;

# Modify the other include file and rebuild
    $t->write('inc_b.h', $file_inc_b2_h);
    $t->build_test;
    $t->test_node_was_not_rebuilt("./1.c");
    $t->test_node_was_rebuilt("./2.c");
    $t->run_target_test(stdout => "inc_a2.h\ninc_b2.h\n");

    $t->test_up_to_date;
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
