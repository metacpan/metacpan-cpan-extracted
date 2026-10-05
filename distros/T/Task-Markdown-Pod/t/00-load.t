#!perl

use Test::More;

use_ok('Task::Markdown::Pod');
is($Task::Markdown::Pod::VERSION, '0.003', 'module version');

done_testing();
