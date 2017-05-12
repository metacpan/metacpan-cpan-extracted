#!/usr/bin/env perl

# Tests for the handling of errors from build commands.

package t::ErrorHandling::BuildError;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Build error');

    $t->build_dir('build_dir');
    $t->target('test-c' . $t::PBS::_exe);

    $t->write('post_pbs.pl', <<'_EOF_');
    for my $node( @{$dependency_tree->{__BUILD_SEQUENCE}}) {
	print "Rebuild node $node->{__NAME}\n";
    }
1;
_EOF_

    $t->command_line_flags('--post_pbs=post_pbs.pl');

    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => '2.o', 'main.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST' ;
_EOF_

    $t->write('main.c', <<'_EOF_');
    void f1(void);
    int main(int argc, char *argv[]) {
	f1();
	+
	return 0;
    }
_EOF_

    $t->write('2.c', <<'_EOF_');
    #include <stdio.h>
    void f1(void);
    void f1(void) {
	printf("2.c\n");
    }
_EOF_
}

sub error_exit_status : Test(1) {
# Build
    $t->build;
    isnt($?, 0, '');
}

sub correct_continuation_after_corrected_error : Test(6) {
# Build
    $t->build;

# Correcting the error in main.c
    $t->write('main.c', <<'_EOF_');
    void f1(void);
    int main(int argc, char *argv[]) {
	f1();
	return 0;
    }
_EOF_

# Build again
	$t->build_test();
    $t->test_node_was_not_rebuilt("./2.c");
    $t->test_node_was_rebuilt("./main.c");
    $t->run_target_test(stdout => "2.c\n");

    $t->test_up_to_date;
}

unless (caller()) {
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
