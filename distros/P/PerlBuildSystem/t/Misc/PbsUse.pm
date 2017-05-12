#!/usr/bin/env perl

# Tests for the PbsUse command.

package t::Misc::PbsUse;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'PbsUse');

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

sub pbs_lib_path : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    PbsUse('Intermediate');
    AddRule 'target', [ 'file.target' => 'file.intermediate' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('Intermediate.pm', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'intermediate', [ '*.intermediate' => '*.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
	
    1 ;
_EOF_
    $t->write('file.in', 'file contents');

# Build
    $t->command_line_flags($t->command_line_flags . " --plp ./");
	 
    $t->build_test;
    $t->test_target_contents('file contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
