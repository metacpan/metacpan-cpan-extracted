use FindBin;
use lib $FindBin::Bin;

use inc::Module::Install;
name 'Number-Phone-JP';
all_from 'lib/Number/Phone/JP.pm';

build_requires 'Test::More';
build_requires 'Test::Requires';
requires 'UNIVERSAL::require' => 0;
requires 'Number::Phone'      => 0;
author_tests 'xt';
repository 'https://github.com/nipotan/p5-Number-Phone-JP';
WriteAll;
