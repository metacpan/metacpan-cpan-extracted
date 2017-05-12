#!/usr/bin/env perl

# Tests for using source directories.

package t::Misc::SourceDirectory;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Source directory');

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

sub multiple_source_directories : Test(2) {
    # Write files
    $t->subdir('subdir', 'subdir2');
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file.in', 'file2.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');
    $t->write('subdir2/file2.in', 'file2 contents');

    # Build
    $t->command_line_flags($t->command_line_flags . ' --source_directory subdir --sd subdir2');
    $t->build_test();
    $t->test_target_contents('file contentsfile2 contents');
}

sub order_between_source_directories : Test(2) {
    # Write files
    $t->subdir('subdir', 'subdir2');
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('subdir/file.in', 'file contents');
    $t->write('subdir2/file.in', 'file2 contents');

    # Build
    $t->command_line_flags($t->command_line_flags . ' --sd subdir2 --sd subdir');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

sub no_search_in_current_directory : Test(2) {
    # Write files
    $t->subdir('subdir');
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'target', ['file.target' => 'file.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('subdir/file.in', 'file2 contents');

    # Build
    $t->command_line_flags($t->command_line_flags . ' --sd subdir');
    $t->build_test();
    $t->test_target_contents('file2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
