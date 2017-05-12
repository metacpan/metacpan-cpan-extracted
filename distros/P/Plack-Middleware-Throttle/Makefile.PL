use inc::Module::Install;
name 'Plack-Middleware-Throttle';
all_from 'lib/Plack/Middleware/Throttle.pm';
readme_from 'lib/Plack/Middleware/Throttle.pm';

requires 'Plack';
requires 'Moose';
requires 'Scalar::Util';
requires 'HTTP::Request::Common';
requires 'DateTime';

tests 't/*.t';

build_requires 'Test::More';
test_requires 'Test::Requires';
use_test_base;
auto_include;
#auto_include_deps;
author_tests 'xt';
auto_set_repository;
WriteAll;
