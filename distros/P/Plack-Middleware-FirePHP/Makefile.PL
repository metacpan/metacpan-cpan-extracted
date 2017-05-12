use inc::Module::Install;
auto_set_repository;

name            'Plack-Middleware-FirePHP';
all_from        'lib/Plack/Middleware/FirePHP.pm';

requires        'Plack'                    => '0.9022';
requires        'Plack::Request'           => '0.09';
requires        'FirePHP::Dispatcher';
requires        'Class::Null';

test_requires   'Test::More'               => '0.92';

tests 't/*.t t/*/*.t';

recursive_author_tests('xt');
author_requires 'Test::Compile';

WriteAll;
