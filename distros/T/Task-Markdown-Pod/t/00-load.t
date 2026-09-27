#!perl

use Test::More;

use_ok('Task::Markdown::Pod');
is($Task::Markdown::Pod::VERSION, '0.001', 'module version');

done_testing();
