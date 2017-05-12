use inc::Module::Install;
name 'Object-Method';
all_from 'lib/Object/Method.pm';

repository 'git://github.com/gugod/Object-Method.git';

tests 't/*.t';
author_tests 'xt/*.t';

build_requires 'Test::More';

auto_include;
WriteAll;
