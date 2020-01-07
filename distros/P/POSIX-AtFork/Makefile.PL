use lib '.';
use strict;
use inc::Module::Install;
use Module::Install::XSUtil;
use Config;

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

if ( $^O eq 'android' ) {
  if ($Config{osvers} lt "2.3.6") {
    # This android doesn't have pthread-atfork()
    cc_src_paths 'android';
  }
}

WriteAll(check_nmake => 0);
