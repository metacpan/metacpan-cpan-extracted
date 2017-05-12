use inc::Module::Install;
name 'Plack-Middleware-ServerName';
all_from 'lib/Plack/Middleware/ServerName.pm';

# requires '';
requires 'parent';
requires 'Plack::Middleware';
requires 'Try::Tiny', 0.06;
tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::TCP';
auto_set_repository;
#auto_include;
WriteAll;

