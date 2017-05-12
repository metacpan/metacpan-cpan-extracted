#!/usr/bin/env perl

# Tests for node attributes in rules.

package t::Rules::NodeAttributes;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Node attributes');

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

sub node_attributes : Test(2) {
# Write files
    $t->subdir('4_56');
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'node attributes', [ 'file.target' => 'file.in::4.56', 'file2.in' ] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    RegisterUserCheckSub(
			 sub {
			     my ($full_name, $user_attribute) = @_;
                             $user_attribute =~ s/\./_/g;
			     return "$user_attribute/file.in";
			 });
_EOF_
    $t->write('file.in', 'file contents');
    $t->write('4_56/file.in', 'file456 contents');
    $t->write('file2.in', 'file2 contents');

# Build
    $t->build_test;
    $t->test_target_contents('file456 contentsfile2 contents');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
