#!/usr/bin/env perl

# Tests the C depender and its handling of dependency cache files.

package t::Correctness::CDepender;

use strict;
use warnings;

use base qw(Test::Class);

use File::Copy::Recursive qw(rcopy);
use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'C depender');

	$t->setup_test_data('c_depender');

    $t->build_dir('build_dir');
    $t->target('test-c.exe');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node ( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl -dsi -dcdi -ndpb -no_colorization');
}

sub copy_from_pbsfiles_dir {
	my ($src,
		$dst) = @_;

	$t->setup_test_data_file('c_depender', $src, $dst);
}

sub change_include_file : Test(8) {
# Build
    $t->build_test;
    $t->run_target_test(stdout => "ab");

    $t->test_up_to_date;

# Modify the first include file and rebuild
	copy_from_pbsfiles_dir('a2.h', 'a.h');
		
    $t->build_test;
    $t->run_target_test(stdout => "a2b");

    $t->test_up_to_date;
}

sub abort_between_build_of_c_and_o_file : Test(4) {
	copy_from_pbsfiles_dir('Pbsfile_abort.pl', 'Pbsfile.pl');
	copy_from_pbsfiles_dir('3.c', '1.c');
	
	$t->build_test;

# Modify the include file and turn on the aborting
# of the build of the .o-file.
	copy_from_pbsfiles_dir('a2.h', 'a.h');
	$ENV{'PBS_TEST_ABORT'} = '1';

# Rebuild.
	$t->build_test_fail;

# Turn off the aborting of the build of the .o-file.	
	$ENV{'PBS_TEST_ABORT'} = '';
	
# Rebuild.	
	$t->build_test;

# Test that the rebuild was correct.
    $t->run_target_test(stdout => "a2");
}

sub use_dependency_cache : Test(4) {
# Build
    $t->build_test;
    $t->run_target_test(stdout => "ab");

# Modify Pbsfile.
	copy_from_pbsfiles_dir('Pbsfile2.pl', 'Pbsfile.pl');
	
# Rebuild.
#
# The C depend caches are up-to-date and will be used.
	$t->build_test;
	
	my $stdout = $t->stdout;
	unlike($stdout, qr|\QC_depender:|, 'The dependency caches are used');
}

sub use_unsynchronized_cache : Test(10) {
# Build
	$t->build_test;
	
# Introduce an error in the first C file and modify the second
# include file.
	copy_from_pbsfiles_dir('1_error.c', '1.c');
	copy_from_pbsfiles_dir('b2.h', 'b.h');
		
# Rebuild.
#
# The second C file will be redepended, but the C depend cache
# of the second C file will not be synchronized, because the
# build will already fail with the compilation of the first C
# file, and that is before the C depend cache of the second C
# file is going to be synchronized.

	$t->build_test_fail;
	
    my $stdout = $t->stdout;
    unlike($stdout, qr|\QSynchronized C cache file for './1.c'|,
		'Did not synchronize C cache for first C file');
	like($stdout, qr|(?x)\QC_depender: '\E[^']*\Q2.c' [MD5 difference]\E\s*
		\Q[\E[^\]]*\Qb.h].|, 'Second C file was redepended');
    unlike($stdout, qr|\QSynchronized C cache file for './2.c'|,
		'Did not synchronize C cache for second C file');

# Fix the error in the first C file.
	copy_from_pbsfiles_dir('1_2.c', '1.c');

# Rebuild.
#
# The C depender will try to redepend the second C file, but it
# will find the unsynchronized cache, verify it, and use it.
	$t->build_test;

    $stdout = $t->stdout;
    like($stdout, qr|\QSynchronized C cache file for './1.c'|,
		'Synchronized C cache for first C file');
    like($stdout, qr|(?x)\QC_depender: '\E[^']*\Q2.c' [MD5 difference]\E\s*
		\Q[\E[^\]]*\Qb.h].\E\s*
		\QVerifying unsynchronized cache ... Valid.|,
		'Found unsynchronized valid cache for second C file');
		
    like($stdout, qr|\QSynchronized C cache file for './2.c'|,
		'Synchronized C cache for second C file');
		
    $t->run_target_test(stdout => "ab2");
}

sub do_not_use_unsynchronized_cache : Test(9) {
# Build
	$t->build_test;
	
# Introduce an error in the first C file and modify the second
# C file to include another include file.
	copy_from_pbsfiles_dir('1_error.c', '1.c');
	copy_from_pbsfiles_dir('2_2.c', '2.c');
		
# Rebuild.
#
# The second C file will be redepended, but the C depend cache
# of the second C file will not be synchronized, because the
# build will already fail with the compilation of the first C
# file, and that is before the C depend cache of the second C
# file is going to be synchronized.
	$t->build_test_fail;
	
    my $stdout = $t->stdout;
    unlike($stdout, qr|\QSynchronized C cache file for './1.c'|,
		'Did not synchronize C cache for first C file');
	like($stdout, qr|(?x)\QC_depender: '\E[^']*\Q2.c' [difference]:\E\s*
		\Q[__VARIABLE:C_FILE].|, 'Second C file was redepended');
    unlike($stdout, qr|\QSynchronized C cache file for './2.c'|,
		'Did not synchronize C cache for second C file');

# Fix the error in the first C file and modify the second C
# file again, now to include a third include file.
	copy_from_pbsfiles_dir('1.c');
	copy_from_pbsfiles_dir('2_3.c', '2.c');

# Rebuild.
#
# The C depender will try to redepend the second C file, but it
# will find the unsynchronized cache, verify it, and find
# that it is invalid (because we modified the second
# include file. So, it will still redepend the second C file.
	$t->build_test;
    $t->run_target_test(stdout => "ab3");

# Change the third include file.
	copy_from_pbsfiles_dir('b.h', 'b3.h');

# Rebuild.
#
# Now, if the invalid unsynchronized cache would have been used,
# the C depend cache would have become wrong by not including
# the third include file. Then, PBS would erroneously think
# everything was up-to-date.
	$t->build_test;
    $t->run_target_test(stdout => "ab");
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
