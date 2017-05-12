#!/usr/bin/env perl

# Tests triggers.

package t::Misc::Triggers;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Triggers');

    $t->build_dir('build_dir');
    $t->target('a.target');

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');
}

sub triggers : Test(3) {
    # Write files
    $t->write_pbsfile(<<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'a.target', ['a.target' => 'c.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    ImportTriggers('trigger.pl');
_EOF_
    $t->write('trigger.pl', <<'_EOF_');
    ExcludeFromDigestGeneration('in-files' => qr/\.in$/);
    AddRule 'b.target', ['b.target' => 'c.in'] =>
	'cat %DEPENDENCY_LIST > %FILE_TO_BUILD';
    sub ExportTriggers {
	AddTrigger('trigger1', [ 'b.target' => 'c.in' ]);
	AddRule 'c.in trigger',
	    {
		NODE_REGEX => '*/b.target',
		PBSFILE => 'trigger.pl',
		PACKAGE => 'package'
	    };
    }
_EOF_
    $t->write('c.in', 'file contents');

    # Build
	 #~ $t->generate_test_snapshot_and_exit ;
    $t->build_test;
    $t->test_file_contents('build_dir/a.target', 'file contents');
    $t->test_file_contents('build_dir/b.target', 'file contents');
}


# This makes the TestClass executable as a standalone script.
unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
