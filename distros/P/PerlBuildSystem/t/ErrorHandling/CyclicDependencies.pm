#!/usr/bin/env perl

# Tests for detection of cycles in the dependency graphs.

package t::ErrorHandling::CyclicDependencies;

use strict;
use warnings;

use base qw(Test::Class);

use Test::More;
use t::PBS;

my $t;

sub setup : Test(setup) {
    $t = t::PBS->new(string => 'Cyclic dependencies');

    $t->build_dir('build_dir');
    $t->target('test-c' . $t::PBS::_exe);
    $t->command_line_flags('-die_source_cyclic_warning');
}

sub cyclic_dependencies : Test(4) {
# Write files
    $t->write_pbsfile(<<"_EOF_");
    PbsUse('Configs/Compilers/gcc');
    PbsUse('Rules/C');

    AddRule 'test-c', [ 'test-c$t::PBS::_exe' => 'main.o', '2.o' ] =>
	'%CC %CFLAGS -o %FILE_TO_BUILD %DEPENDENCY_LIST' ;
_EOF_

    $t->write('inc_a.h', <<'_EOF_');
    #ifndef _INC_A_H_
    #define _INC_A_H_

    #include "inc_b.h"

    void a(void);

    #endif
_EOF_

    $t->write('inc_b.h', <<'_EOF_');
    #ifndef _INC_B_H_
    #define _INC_B_H_

    #include "inc_a.h"

    void b(void);

    #endif
_EOF_

    $t->write('main.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_a.h"
    
    void a(void) {
	printf("a\n");
    }

    int main(int argc, char *argv[]) {
	b();
	printf("main.c\n");
	return 0;
    }
_EOF_

    $t->write('2.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_b.h"
    
    void b(void) {
	a();
	printf("b\n");
    }
_EOF_

    # Build
	$t->build;
    my $stdout = $t->stdout;
    like($stdout, qr|Cycle at node '.*inc_a\.h'.*Cycle at node '.*inc_b\.h.'*|ms, '');

    # Build again (earlier this was a bug, cyclic dependencies was not
    # detected at second build).
    $t->build;
    $stdout = $t->stdout;

#~ $t->generate_test_snapshot_and_exit();

    like($stdout, qr|.*Cycle at node '.*inc_a\.h'.*Cycle at node '.*inc_b\.h'|ms, '');

    # Removing the cyclic dependency
    $t->write('inc_b.h', <<'_EOF_');
    #ifndef _INC_B_H_
    #define _INC_B_H_

    void b(void);

    #endif
_EOF_

    $t->write('2.c', <<'_EOF_');
    #include <stdio.h>
    #include "inc_a.h"
    
    void b(void) {
	a();
	printf("b\n");
    }
_EOF_

    $t->build_test;
    $t->run_target_test(stdout => "a\nb\nmain.c\n");
}

unless (caller()) {
    #    t::PBS::set_global_warp_mode('1.0');
    $ENV{"TEST_VERBOSE"} = 1;
    Test::Class->runtests;
}

1;
