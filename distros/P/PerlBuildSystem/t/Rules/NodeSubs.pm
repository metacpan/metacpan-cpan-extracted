#!/usr/bin/env perl

# Tests for node subs in rules.

package t::Rules::NodeSubs;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Node subs');

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

sub node_subs : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddConfig('VARIABLE1' => 'value1');
    AddRule 'node sub', [ 'file.target' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST %VARIABLE1 > %FILE_TO_BUILD',
	[ \&NodeSub ];
    sub NodeSub {
	my ($dependent_to_check, $config, $tree, $inserted_nodes) = @_;
	$tree->{__CONFIG} = {%{$tree->{__CONFIG}}};
	$tree->{__CONFIG}{VARIABLE1} = 'value2';
    }
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('value1', 'file value1 contents');
    $t->write('value2', 'file2 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file contentsfile2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
