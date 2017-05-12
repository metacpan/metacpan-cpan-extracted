use inc::Module::Install;

name 'Money-ChangeMaker';
all_from 'lib/Money/ChangeMaker.pm';

build_requires('Test::Pod' => 1.26);
build_requires('Test::Pod::Coverage' => 1.08);
build_requires('Pod::Coverage' => 0.18);

auto_install;
WriteAll;
