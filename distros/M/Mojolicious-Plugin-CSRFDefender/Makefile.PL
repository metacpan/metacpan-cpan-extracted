use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;

name     'Mojolicious-Plugin-CSRFDefender';
author   'Yuki Shibazaki <shibayu36@gmail.com>';
all_from 'lib/Mojolicious/Plugin/CSRFDefender.pm';

requires 'Mojolicious' => '1.43';
requires 'String::Random';
requires 'Class::Accessor::Fast';
requires 'Path::Class';

test_requires 'Test::More';
test_requires 'Test::Class';
test_requires 'Mojolicious::Lite';
test_requires 'Test::Mojo';

recursive_author_tests('xt');

WriteAll;

