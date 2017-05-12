#!/usr/bin/env perl

# Template for a test class.

package t::TestClassTemplate; # Change this!

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    # Change the description!
    $t = t::PBS->new(string => 'Test class template');

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

# Change the name of the method and write a testcase in the method body.
# Replace num_tests with the number of tests in the method.
# Write additional methods like this one if needed.
sub testcase_1 : Test(num_tests) {
}


# This makes the TestClass executable as a standalone script.
unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
