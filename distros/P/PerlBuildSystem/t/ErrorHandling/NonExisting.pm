#!/usr/bin/env perl

# Tests for error handling on non existing targets and files.

package t::ErrorHandling::NonExisting;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Non existing targets and files');

    $t->build_dir('build_dir');
    $t->target('test-c');
}

sub non_existing_targets : Test(1) {
# Write file
    $t->write_pbsfile(<<'_EOF_');
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'wrong-target' => 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST' ;
_EOF_

# Build
    $t->build;
    my $stderr = $t->stderr;
    like($stderr, qr|No matching rule|, 'Correct error message on non existing target');
}

sub non_existing_files : Test(1) {
# Write file
    $t->write_pbsfile(<<'_EOF_');
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c' => 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST' ;
_EOF_

# Build
    $t->build;
    my $stderr = $t->stderr;
    like($stderr, qr|non existing C file: '\./main\.c'|, 'Correct error message on non existing file');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
