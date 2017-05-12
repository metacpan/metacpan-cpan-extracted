use inc::Module::Install;
name 'Term-QRCode';
all_from 'lib/Term/QRCode.pm';

requires 'Carp';
requires 'FindBin';
requires 'Term::ANSIColor';
requires 'Text::QRCode';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

install_script 'term-qrcode';

use_test_base;
auto_include;
WriteAll;
