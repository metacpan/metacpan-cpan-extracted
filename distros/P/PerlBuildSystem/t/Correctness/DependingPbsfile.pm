#!/usr/bin/env perl

# Tests that a node have the same "dependency Pbsfile", irrespective of where
# it was inserted in the dependency graph.

package t::Correctness::DependingPbsfile;

use strict;
use warnings;

use base qw(Test::Class);

use File::Copy::Recursive qw(rcopy);
use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Depending Pbsfile');

	$t->setup_test_data('depending_pbsfile');

    $t->build_dir('build_dir');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node ( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

sub depending_pbsfile : Test(5) {
# Build 'all2'
#
# The following happens:
# 1. Insert './2' in Pbsfile.pl.
# 2. Insert './1' in Pbsfile.pl.
# 3. Depend './2' in Subpbs.pl.
# 4. Depend './1' in Subpbs.pl.
# 5. Link existing './2' to './1'
# 
# './2' should have Subpbs.pl as "dependency Pbsfile". This will be written in
# the digest for './2'.
	$t->target('all2');
    $t->build_test;
	$t->test_target_contents('22');

# Build 'all'
#
# The following happens:
# 1. Insert './1' in Pbsfile.pl.
# 2. Insert './2' in Pbsfile.pl.
# 3. Depend './1' in Subpbs.pl.
# 4. Link existing './2' to './1' in Subpbs.pl, although './1' is not depended
#    yet.
# 5. Depend './2' in Subpbs.pl.
#
# './2' should have Subpbs.pl as "dependency Pbsfile" here as well.
# Currently, there is a bug have the consequence that './2' has Pbsfile.pl as
# "dependency Pbsfile", the as it was inserted in, not depended in.
#
# The digest for './2' should be the same, irrespective of which target was
# built. This will not be the case if './2' have another "dependency Pbsfile",
# and as a consequence, './2' will be rebuilt.
	$t->target('all');
    $t->build_test;
	$t->test_target_contents('22');
	$t->test_node_was_not_rebuilt('./2');
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
