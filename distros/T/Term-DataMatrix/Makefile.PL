use inc::Module::Install;
name 'Term-DataMatrix';
all_from 'lib/Term/DataMatrix.pm';

requires 'Carp';
requires 'FindBin';
requires 'Term::ANSIColor';
requires 'Barcode::DataMatrix';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

install_script 'term-datamatrix';

use_test_base;
auto_include;
WriteAll;
