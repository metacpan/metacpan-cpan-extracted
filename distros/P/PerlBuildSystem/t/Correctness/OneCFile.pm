#!/usr/bin/env perl

# Tests for correctness in building, that is files are rebuilt when
# they should, and not rebuilt when they should not.
# These tests all uses programs with one C file.

package t::Correctness::OneCFile;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'One C file');

    $t->build_dir('build_dir');
    $t->target('test-c' . $t::PBS::_exe);

# Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST' ;
_EOF_

    $t->write('main.c', <<'_EOF_');
    #include <stdio.h>
    int main(int argc, char *argv[]) {
	printf("main.c\n");
	return 0;
    }
_EOF_
}

my $file_main2_c = <<'_EOF_';
#include <stdio.h>
int main(int argc, char *argv[]) {
    printf("main2.c\n");
    return 0;
}
_EOF_

sub normal_build : Test(18) {
# Build
    $t->build_test;
    $t->run_target_test(stdout => "main.c\n");

    $t->test_up_to_date;

# Modify the c-file and rebuild
    $t->write('main.c', $file_main2_c);
    $t->build_test;
    #~ $t->generate_test_snapshot_and_exit() ;
    $t->run_target_test(stdout => "main2.c\n");

    $t->test_up_to_date;

# Remove the object file and rebuild
    $t->remove_file_from_build_dir('main.o');
    $t->build_test;
    $t->test_file_exist_in_build_dir('main.o');
    $t->run_target_test(stdout => "main2.c\n");

    $t->test_up_to_date;

# Remove the program and rebuild
    $t->remove_file_from_build_dir('test-c' . $t::PBS::_exe);
    $t->build_test;
    $t->test_file_exist_in_build_dir('test-c' . $t::PBS::_exe);
    $t->run_target_test(stdout => "main2.c\n");

    $t->test_up_to_date;
}

sub wrong_timestamp : Test(6) {
# Build
    $t->build_test;
    $t->run_target_test(stdout => "main.c\n");

# Modify the c-file but set the timestamp so file seems to be older then the object file
    $t->write('main.c', $file_main2_c);
    my $time = (stat($t->catfile($t->build_dir, 'main.o')))[9];
    $time -= 2;
    utime($time, $time, 'main.c');
    $t->build_test;
    $t->run_target_test(stdout => "main2.c\n");

    $t->test_up_to_date;
}

sub wrong_timestamp2 : Test(4) {
# Build
    $t->build_test;
    $t->run_target_test(stdout => "main.c\n");

# Update the timestamp of the c-file
    my $time = (stat('main.c'))[0];
    $time += 1;
    utime($time, $time, 'main.c');
    my $sleep = $time - time;
    sleep($sleep) if $sleep > 0;

    $t->test_up_to_date;
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
