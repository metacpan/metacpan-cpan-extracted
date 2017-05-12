use inc::Module::Install;
name 'Plack-Middleware-ReverseProxy';
all_from 'lib/Plack/Middleware/ReverseProxy.pm';

requires 'parent';
requires 'Plack', 0.9988;
requires 'Plack::Middleware';
requires 'Plack::Request';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
WriteAll;
