use strict;
use warnings;
use inc::Module::Install 1.06;
use Module::Install::TestTarget 0.19;

all_from 'lib/MouseX/NativeTraits.pm';

requires 'Mouse' => 0.82;

test_requires 'Any::Moose'  => 0.13;
test_requires 'Test::More'  => 0.88; # done_testing()
test_requires 'Test::Fatal' => 0.003;

tests_recursive 't';
author_tests 'xt';

auto_set_repository() if -d '.git';

default_test_target
    env => { ANY_MOOSE => 'Mouse' };

test_target 'test_moose' => (
    env => { ANY_MOOSE => 'Moose' },
);

clean_files qw(
    MouseX-NativeTraits-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
