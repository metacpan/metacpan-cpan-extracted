use strict;
use warnings;
use inc::Module::Install;

name('MogileFS-Plugin-MultiHook');
author('Toru Yamaguchi <zigorou@cpan.org>');
all_from('lib/MogileFS/Plugin/MultiHook.pm');
license('perl');

requires('MogileFS::Server');
requires('MogileFS::Config');

use_test_base;

auto_include;
auto_install;

WriteAll;
