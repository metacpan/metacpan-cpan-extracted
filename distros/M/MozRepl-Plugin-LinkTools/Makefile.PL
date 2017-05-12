use inc::Module::Install;

name('MozRepl-Plugin-LinkTools');
author('Toru Yamaguchi <zigorou@cpan.org>');
version('0.01');
abstract('Link Plugin for MozRepl');
license('perl');

requires('MozRepl', 0.04);

requires("Carp::Clan", 5.8);
requires("JSON", 1.14);
requires("JSON::Any", 1.08);

use_test_base;

auto_include;
auto_install;

WriteAll;
