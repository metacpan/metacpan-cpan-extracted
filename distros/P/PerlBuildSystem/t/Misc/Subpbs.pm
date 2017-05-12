#!/usr/bin/env perl

# Tests for using sub pbs files.

package t::Misc::Subpbs;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Subpbs');

    $t->build_dir('build_dir');
    $t->target('file.target');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');

    $t->subdir('subdir');
}

sub node_regex_pbsfile : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddRule 'target', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'subdir', { NODE_REGEX => '*/subdir/file.intermediate',
			PBSFILE => 'subdir/Pbsfile.pl',
			PACKAGE => 'subdir' };
_EOF_
    $t->subdir('subdir');
    $t->write('subdir/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '%TARGET_PATH/file.intermediate' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub subpbs_package : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddRule 'target', [ 'file.target' => 'subdir/file.intermediate',
			                 'subdir2/file.intermediate',
			                 'subdir3/file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'subdir', { NODE_REGEX => '*/subdir/file.intermediate',
			PBSFILE => 'subdir/Pbsfile.pl',
			PACKAGE => 'package_a' };
    AddRule 'subdir2', { NODE_REGEX => '*/subdir2/file.intermediate',
			 PBSFILE => 'subdir2/Pbsfile.pl',
			 PACKAGE => 'package_a' };
    AddRule 'subdir3', { NODE_REGEX => '*/subdir3/file.intermediate',
			 PBSFILE => 'subdir3/Pbsfile.pl',
			 PACKAGE => 'package_b' };
_EOF_
    $t->subdir('subdir', 'subdir2', 'subdir3', 'subdir4');
    $t->write('subdir/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '%TARGET_PATH/file.intermediate' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir2/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '%TARGET_PATH/file.intermediate' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir3/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '%TARGET_PATH/file.intermediate' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');
    $t->write('subdir2/file.in', 'file2 contents');
    $t->write('subdir3/file.in', 'file3 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contentsfile2 contentsfile3 contents');
}

sub rules_are_not_inherited : Test(2) {
# It is a intermediate2 rule in both the pbsfile and sub-pbsfile, but with
# different builders. Check that the correct rule is used.

# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate2', [ 'subdir/*.intermediate2' => '*.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'target', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'subdir', { NODE_REGEX => '*/subdir/file.intermediate',
			PBSFILE => 'subdir/Pbsfile.pl',
			PACKAGE => 'subdir' };
_EOF_
    $t->subdir('subdir');
    $t->write('subdir/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '%TARGET_PATH/*.intermediate' => '*.intermediate2' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'intermediate2', [ '%TARGET_PATH/*.intermediate2' => '*.in' ] =>
	'echo %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_file_contents_regex($t->get_target_with_path, qr|/subdir/file.in|);
}

sub configuration_is_inherited_with_higher_priority : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddConfig('FILE1' => 'file2.in');
    AddRule 'target', [ 'file.target' => 'subdir/file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'subdir', { NODE_REGEX => '*/subdir/file.intermediate',
			PBSFILE => 'subdir/Pbsfile.pl',
			PACKAGE => 'subdir' };
_EOF_
    $t->subdir('subdir');
    $t->write('subdir/Pbsfile.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddConfig('FILE1' => 'file3.in');
    AddRule 'intermediate', [ '%TARGET_PATH/file.intermediate' => 'file.in' ] =>
	'cat subdir/%FILE1 %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');
    $t->write('subdir/file2.in', 'file2 contents');
    $t->write('subdir/file3.in', 'file3 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file2 contentsfile contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
