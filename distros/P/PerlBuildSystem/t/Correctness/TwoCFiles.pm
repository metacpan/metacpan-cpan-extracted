#!/usr/bin/env perl

# Tests for correctness in building, that is files are rebuilt when
# they should, and not rebuilt when they should not.
# These tests all uses programs with two C files.

package t::Correctness::TwoCFiles;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Two C files');

    $t->build_dir('build_dir');
    $t->target('test-c' . $t::PBS::_exe);

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

my $file1_c = <<'_EOF_';
#include <stdio.h>
void f1(void);
void f1(void) {
    printf("1.c\n");
}
_EOF_

my $file1_2_c = <<'_EOF_';
#include <stdio.h>
void f1(void);
void f1(void) {
    printf("1_2.c\n");
}
_EOF_

my $file1_3_c = <<'_EOF_';
#include <stdio.h>
void f1(void);
void f1(void) {
    printf("1_3.c\n");
}
_EOF_

my $file2_c = <<'_EOF_';
#include <stdio.h>
void f1(void);
int main(int argc, char *argv[]) {
    f1();
    printf("2.c\n");
    return 0;
}
_EOF_

my $file2_3_c = <<'_EOF_';
#include <stdio.h>
void f1(void);
int main(int argc, char *argv[]) {
    f1();
    printf("2_3.c\n");
    return 0;
}
_EOF_

sub one_directory : Test(16) {
# Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => '1.o', '2.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';
_EOF_

    $t->write('1.c', $file1_c);
    $t->write('2.c', $file2_c);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "1.c\n2.c\n");

    $t->test_up_to_date;

# Modify one of the c-files and rebuild
    $t->write('1.c', $file1_2_c);
    $t->build_test;
    $t->test_node_was_rebuilt("./1.c");
    $t->test_node_was_not_rebuilt("./2.c");
    $t->run_target_test(stdout => "1_2.c\n2.c\n");

    $t->test_up_to_date;

# Modify both c-files and rebuild
    $t->write('1.c', $file1_3_c);
    $t->write('2.c', $file2_3_c);
    $t->build_test;
    $t->test_node_was_rebuilt("./1.c");
    $t->test_node_was_rebuilt("./2.c");
    $t->run_target_test(stdout => "1_3.c\n2_3.c\n");

    $t->test_up_to_date;
}

sub subdirectories : Test(16) {
# Create directories
    $t->subdir('dir1', 'dir2');

# Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'dir1/1.o', 'dir2/2.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST';

    AddSubpbsRule('dir1', 'dir1/1.o', 'dir1/Pbsfile.pl', 'dir1');
    AddSubpbsRule('dir2', 'dir2/2.o', 'dir2/Pbsfile.pl', 'dir2');
_EOF_

    $t->write('dir1/Pbsfile.pl', <<'_EOF_');
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');
_EOF_

    $t->write('dir2/Pbsfile.pl', <<'_EOF_');
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');
_EOF_

    $t->write('dir1/1.c', $file1_c);
    $t->write('dir2/2.c', $file2_c);

# Build
    $t->build_test;
    $t->run_target_test(stdout => "1.c\n2.c\n");

    $t->test_up_to_date;

# Modify one of the c-files and rebuild
    $t->write('dir1/1.c', $file1_2_c);
    $t->build_test;
    $t->test_node_was_rebuilt("./dir1/1.c");
    $t->test_node_was_not_rebuilt("./dir2/2.c");
    $t->run_target_test(stdout => "1_2.c\n2.c\n");

    $t->test_up_to_date;

# Modify both c-files and rebuild
    $t->write('dir1/1.c', $file1_3_c);
    $t->write('dir2/2.c', $file2_3_c);
    $t->build_test;
    $t->test_node_was_rebuilt("./dir1/1.c");
    $t->test_node_was_rebuilt("./dir2/2.c");
    $t->run_target_test(stdout => "1_3.c\n2_3.c\n");

    $t->test_up_to_date;

}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
