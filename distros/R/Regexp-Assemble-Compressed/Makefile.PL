use strict;
use inc::Module::Install;
name 'Regexp-Assemble-Compressed';
all_from 'lib/Regexp/Assemble/Compressed.pm';

perl_version '5.008001';
build_requires 'Test::More';
requires 'Regexp::Assemble';
auto_include;
WriteAll;
