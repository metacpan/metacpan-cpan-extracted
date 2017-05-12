use inc::Module::Install;

name('Template-Stash-Encode');
author('Toru Yamaguchi <zigorou@cpan.org>');
abstract('Encode charactor code on stash variables');
version_from('lib/Template/Stash/Encode.pm');
license('perl');

requires('Encode');
requires('Template');
requires('Template::Config');
requires('Template::Stash');

use_test_base;

build_requires('Test::Pod');
build_requires('Test::Pod::Coverage');

auto_include;
auto_install;

WriteAll;
