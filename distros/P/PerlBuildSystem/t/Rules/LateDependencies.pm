#!/usr/bin/env perl

# Tests for different ways to specify dependencies in rules.

package t::Rules::Dependencies;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Dependencies');

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

sub late_depend : Test(6) {
    $t->write_pbsfile(<<'_EOF_');
AddRule [VIRTUAL], 'all',['file.target' => 'something', 'late'], BuildOk() ;
AddSubpbsRule 'sub_pbsfile', 'something', './subpbs.pl', 'name with spaces' ;
_EOF_

    $t->write('subpbs.pl', <<'_EOF_');
AddRule 'something', ['*/something' => 'late'] ;
AddRule 'late', ['late' => 'late_dependency'] ;
_EOF_

    $t->command_line_flags('-nh -dd');

    $t->build_test;
    
    like($t->stdout
	, qr|Linking '\./late' \(from \./Pbsfile\.pl -> all\)\n.*Above node is not depended yet|
	, 'Linking undepended node');

    like($t->stdout
	, qr|'\Q./late' has dependencies [./late_dependency], rule 2:late|
	, 'Depending linked node');

    like($t->stdout
	, qr|\Q./late_dependency' wasn't depended (rules from './subpbs.pl').|
	, 'linked node dependency is not depended locally');

	like($t->stdout
	, qr|\QNode './late' inserted at rule: all  [Pbsfile: ./Pbsfile.pl] has been depended in Pbsfile: '/\E.*/subpbs.pl'.|
	, 'warn for node depended elsewhere');
	
    like($t->stdout
	, qr|\QNode './late_dependency' was not depended! Node wa inserted at|
	, 'warn for undepended node');
}


unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
