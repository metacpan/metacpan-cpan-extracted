#!/usr/bin/env perl

# Tests for the ReplaceRule command.

package t::Rules::ReplaceRule;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'ReplaceRule and RemoveRule');

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

sub replace_rule : Test(2) {
# Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'rule', [ 'file.target' => 'file.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    ReplaceRule 'rule', [ 'file.target' => 'file2.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('file2.in', 'file2 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file2 contents');
    
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
