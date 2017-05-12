use inc::Module::Install;
name 'Number-ZipCode-JP';
all_from 'lib/Number/ZipCode/JP.pm';

build_requires 'Test::More';
requires 'UNIVERSAL::require' => 0;
author_tests 'xt';
repository 'https://github.com/nipotan/p5-Number-ZipCode-JP';
WriteAll;
