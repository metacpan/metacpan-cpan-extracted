use inc::Module::Install;
name 'Plack-Middleware-Log-Minimal';
all_from 'lib/Plack/Middleware/Log/Minimal.pm';

# requires '';
requires 'parent';
requires 'Log::Minimal', 0.09;
requires 'Plack::Middleware';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
#auto_include;
WriteAll;
