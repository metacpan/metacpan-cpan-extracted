use inc::Module::Install;

all_from 'lib/MouseX/StrictConstructor.pm';

requires 'Mouse' => '0.62';

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

WriteAll(check_nmake => 1);
