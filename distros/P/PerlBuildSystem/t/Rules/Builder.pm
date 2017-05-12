#!/usr/bin/env perl

# Tests for different builders in rules.

package t::Rules::Builder;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Builder');

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

sub builder_sub : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'builder sub', [ 'file.target' => 'file.in' ] =>
	sub {
	    my ($config,
		$file_to_build,
		$dependencies,
		$triggering_dependencies,
		$file_tree,
		$inserted_nodes) = @_;
	    if (! (defined($config) &&
		   defined($file_to_build) &&
		   defined($dependencies) &&
		   defined($triggering_dependencies) &&
		   defined($file_tree) &&
		   defined($inserted_nodes))) {
		return 0, 'Builder sub arguments error';
	    }
	    system("cat @$dependencies > $file_to_build");
	    return 1, 'Builder sub message';
	};
_EOF_
	$t->write('file.in', 'file contents');

	# Build
	$t->build_test;
    $t->test_target_contents('file contents');
}

sub builder_sub_error : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'builder sub', [ 'file.target' => 'file.in' ] =>
	sub {
	    return 0, 'Builder sub error';
	};
_EOF_
    $t->write('file.in', 'file contents');

# Build
	$t->build_test_fail;
    my $stderr = $t->stderr;
    like($stderr, qr/BUILD_FAILED : Builder sub error/, 'Error message from builder sub');
}

sub builder_sub_shell : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'builder sub', [ 'file.target' => 'file.in' ] =>
	sub {
	    my $config = shift;
	    my $file_to_build = shift;
	    my $dependencies = shift;
	    PBS::Shell::RunShellCommands("cat @$dependencies > $file_to_build");
	    return 1, 'Builder sub message';
	};
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub builder_sub_shell_error : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'builder sub', [ 'file.target' => 'file.in' ] =>
	sub {
	    PBS::Shell::RunShellCommands('./errorcommand');
	};
_EOF_
    $t->write('file.in', 'file contents');

# Build
	$t->build_test_fail;
    my $stderr = $t->stderr;
    like($stderr, qr/Shell command failed!/, 'Error message from PBS::Shell::RunShellCommands');
}

sub shell_commands_multiple : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'multiple commands', [ 'file.target' => 'file.in' ] =>
	[ 'cat %DEPENDENCY_LIST > file.intermediate',
	  'cat file.intermediate > %FILE_TO_BUILD'];
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contents');
}

sub shell_commands_configuration : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddConfig('VARIABLE1' => 'value1');
    AddRule 'configuration', [ 'file.target' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST %VARIABLE1 > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('value1', 'file2 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contentsfile2 contents');
}

sub shell_commands_file_to_build_dependency_list : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'file to build dependency list', [ 'file.target' => 'file.in', 'file2.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');

# Build
	$t->build_test;
    $t->test_target_contents('file contentsfile2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
