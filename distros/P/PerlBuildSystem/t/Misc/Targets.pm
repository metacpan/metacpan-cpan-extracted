#!/usr/bin/env perl

# Tests for specifying targets.

package t::Misc::Targets;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Targets');

    $t->build_dir('build_dir');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

sub multiple_targets : Test(4) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'a', ['a' => 'a.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'b', ['b' => 'b.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'c', ['c' => 'c.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('a.in', 'file contents');
    $t->write('b.in', 'file2 contents');
    $t->write('c.in', 'file3 contents');

    # Build
    $t->build_test('targets' => 'c b');
    $t->test_file_not_exist_in_build_dir('a');
    $t->test_file_contents($t->catfile($t->build_dir, 'b'), 'file2 contents');
    $t->test_file_contents($t->catfile($t->build_dir, 'c'), 'file3 contents');
}

sub default_target : Test(3) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'a', ['a' => 'a.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    AddRule 'b', ['b' => 'b.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('pbs.prf', "AddTargets('b') ;\n");
    $t->write('a.in', 'file contents');
    $t->write('b.in', 'file2 contents');

    # Build
    $t->build_test();
    $t->test_file_not_exist_in_build_dir('a');
    $t->test_file_contents($t->catfile($t->build_dir, 'b'), 'file2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
