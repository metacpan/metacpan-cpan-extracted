use inc::Module::Install;

name('MozRepl-Plugin-Restart');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/MozRepl/Plugin/Restart.pm');
abstract_from('lib/MozRepl/Plugin/Restart.pm');
license('perl');

requires('MozRepl', 0.02);
requires('Pod::Usage');
requires('Getopt::Long');

use_test_base;

install_script('bin/mozrestart');

auto_include;
auto_install;

WriteAll;

