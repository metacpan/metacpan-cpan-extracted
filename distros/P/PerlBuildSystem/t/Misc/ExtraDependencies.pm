#!/usr/bin/env perl

# Tests for adding extra dependencies to a node, i.e. changing
# the digest generation.

package t::Misc::ExtraDependencies;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Extra dependencies');

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

sub add_file_dependencies : Test(10) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddFileDependencies('dependency');
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('dependency', 'dependency contents');

    # Build
    $t->build_test();
    $t->test_target_contents('file contents');

    $t->test_up_to_date;

    # Modify the extra dependency file and rebuild
    $t->write('dependency', 'dependency2 contents');
    $t->build_test();
    if ($t->get_global_warp_mode ne 'off') {
	TODO: {
	    local $TODO = 'AddFileDependencies does not work in warp';
	    $t->test_node_was_rebuilt('./file.target');
	}
    } else {
	$t->test_node_was_rebuilt('./file.target');
    }
    $t->test_up_to_date;

    # Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub add_environment_dependencies : Test(10) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddEnvironmentDependencies('PBS_TEST_VARIABLE');
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $ENV{'PBS_TEST_VARIABLE'} = 'value1';

    # Build
    $t->build_test();
    $t->test_target_contents('file contents');

    $t->test_up_to_date;

    # Modify the environment variable and rebuild
    $ENV{'PBS_TEST_VARIABLE'} = 'value2';
    $t->build_test();
    if ($t->get_global_warp_mode ne 'off') {
	TODO: {
	    local $TODO = 'AddEnvironmentDependencies does not work in warp';
	    $t->test_node_was_rebuilt('./file.target');
	}
    } else {
	$t->test_node_was_rebuilt('./file.target');
    }
    $t->test_up_to_date;

    # Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub add_switch_dependencies : Test(12) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddSwitchDependencies('-Dtest_variable');
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

    # Build
    my $org_flags = $t->command_line_flags;
    $t->command_line_flags($org_flags . ' -D=test_variable=value1');
    $t->build_test();
    $t->test_target_contents('file contents');

    $t->test_up_to_date;

    # Modify the variable and rebuild
    $t->command_line_flags($org_flags . ' -D=test_variable=value2');
    $t->build_test();
    $t->test_node_was_rebuilt('./file.target');
    $t->test_up_to_date;

    # Modify another variable and rebuild
    $t->command_line_flags($org_flags . ' -D=test2_variable=value3 -D=test_variable=value2');
    $t->test_up_to_date;

    # Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub add_switch_dependencies_wildcards : Test(14) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddSwitchDependencies('-D*');
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

    # Build
    my $org_flags = $t->command_line_flags;
    $t->command_line_flags($org_flags . ' -D=test_variable=value1');
    $t->build_test();
    $t->test_target_contents('file contents');

    $t->test_up_to_date;

    # Modify the variable and rebuild
    $t->command_line_flags($org_flags . ' -D=test_variable=value2');
    $t->build_test();
    $t->test_node_was_rebuilt('./file.target');
    $t->test_up_to_date;

    # Modify another variable and rebuild
    $t->command_line_flags($org_flags . ' -D=test2_variable=value3 -D=test_variable=value2');
    $t->build_test();
    $t->test_node_was_rebuilt('./file.target');
    $t->test_up_to_date;

    # Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub add_variable_dependency : Test(10) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    my $test_variable = `cat dependency`;
    AddVariableDependencies('test_variable' => $test_variable);
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('dependency', 'dependency contents');

    # Build
    $t->build_test();
    $t->test_target_contents('file contents');

    $t->test_up_to_date;

    # Modify the extra dependency file and rebuild
    $t->write('dependency', 'dependency2 contents');
    $t->build_test();
    if ($t->get_global_warp_mode ne 'off') {
	TODO: {
	    local $TODO = 'AddVariableDependency does not work in warp';
	    $t->test_node_was_rebuilt('./file.target');
	}
    } else {
	$t->test_node_was_rebuilt('./file.target');
    }
    $t->test_up_to_date;

    # Modify the in-file and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub force_digest_generation : Test(10) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file2.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'file2', ['file2.in' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');

    # Build
    $t->build_test();
    $t->test_target_contents('file contents');

    # Modify the leaf node and rebuild
    $t->write('file.in', 'file2 contents');
    $t->test_up_to_date;

    # Rewrite the pbs-file, with force digest on the intermediate node
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    ForceDigestGeneration('file2.in is generated' => qr|file2\.in$|);
    AddRule 'target', ['file.target' => 'file2.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'file2', ['file2.in' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_

    # Build
    $t->write('file.in', 'file contents');
    $t->build_test();
    $t->test_target_contents('file contents');

    # Modify the leaf node and rebuild
    $t->write('file.in', 'file2 contents');
    $t->build_test();
    $t->test_target_contents('file2 contents');

    $t->test_up_to_date;
}


unless (caller()) {
    #t::PBS::set_global_warp_mode('1.0');
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
