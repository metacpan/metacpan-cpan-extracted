use inc::Module::Install;

name 'Plack-Middleware-DefaultDocument';
all_from 'lib/Plack/Middleware/DefaultDocument.pm';
readme_from 'lib/Plack/Middleware/DefaultDocument.pm';
authority 'ZIGUZAGU';

tests 't/*.t';
author_tests 'xt';

auto_include;
auto_set_repository;

cpanfile;

WriteAll;
