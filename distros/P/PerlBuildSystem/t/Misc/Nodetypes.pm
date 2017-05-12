#!/usr/bin/env perl

# Tests for different node types.

package t::Misc::Nodetypes;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Node types');

    $t->build_dir('build_dir');
    $t->target('file.target');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

sub type_virtual : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule [VIRTUAL], 'all', [ 'all' => 'file.target' ] =>
    	sub {
    	    return 1, 'Builder sub message';
    	};
    AddRule 'target', [ 'file.target' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
# Build
    $t->build_test('targets' => 'all');
    $t->test_target_contents('file contents');
}

sub type_virtual_no_dependencies : Test(3) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddRule [VIRTUAL], 'no dependencies', [ 'file.target' => undef ] =>
	'cat file.in > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->test_up_to_date;
    $t->test_file_not_exist_in_build_dir('file.target');
}

sub type_local : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule [LOCAL], 'file.in', [ 'file.in' => undef ];
_EOF_
    $t->write('file.in', 'file contents');

    # Build
    $t->build_test('targets' => 'file.in');
    $t->test_file_contents($t->catfile($t->build_dir, 'file.in'), 'file contents');
}

sub type_forced : Test(4) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddRule [FORCED], 'file.target', [ 'file.target' => undef ] =>
	'cat file.in > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

    # Build
    $t->build_test();
    $t->test_target_contents('file contents');

    # Modify the in-file and check that it rebuilds
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub type_virtual_forced : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    AddRule [VIRTUAL, FORCED], 'forced', [ 'file.target' => undef ] =>
	'cat file.in > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test();
    $t->test_target_contents('file contents');
}

sub type_immediate_build : Test(2) {
    # This test uses the result of the immediate build (file2.intermediate)
    # in the normal build, without having file2.intermediate as a
    # dependency. The build order is such that file2.intermediate
    # would be built after it is used if it was not an immediate build.

    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file.intermediate',
                                        'file2.intermediate'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule [IMMEDIATE_BUILD], 'ib', ['file2.intermediate' => 'file2.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'intermediate', ['file.intermediate' => 'file.in'] =>
	'cat build_dir/file2.intermediate %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');

    # Build
	$t->build_test();
    $t->test_target_contents('file2 contentsfile contentsfile2 contents');
}

sub type_post_depend : Test(2) {
    # The end result is dependent on the dependency order.
    # POST_DEPEND changes the resulting dependency order,
    # and hence the end result.

    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file.in'];
    AddRule [POST_DEPEND], 'post_depend', ['file.target' => 'file2.in'];
    AddRule 'target2', ['file.target' => 'file3.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');
    $t->write('file3.in', 'file3 contents');

    # Build
    $t->build_test();
    $t->test_target_contents('file contentsfile3 contentsfile2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
