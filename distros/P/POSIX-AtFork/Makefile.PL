use strict;
use inc::Module::Install;
use Module::Install::XSUtil;

all_from 'lib/POSIX/AtFork.pm';

cc_warnings;
use_ppport;

cc_libs 'pthread';

test_requires 'Test::SharedFork';
test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;

clean_files q{
    *.o
};

WriteAll(check_nmake => 0);
