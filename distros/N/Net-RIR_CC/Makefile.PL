use inc::Module::Install;

name     'Net-RIR_CC';
all_from 'lib/Net/RIR_CC.pm';
author   q{Gavin Carr <gavin@openfusion.com.au>};
license  'perl';

requires 'Mouse';
requires 'File::ShareDir';
requires 'HTML::TableExtract';

build_requires 'Test::More';

auto_install;
install_share;

WriteAll;

