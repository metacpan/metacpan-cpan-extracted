use inc::Module::Install;

name('Nagios-Plugins-Memcached');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/Nagios/Plugins/Memcached.pm');
abstract('Nagios plugin to observe memcached');
license('perl');

requires('Carp::Clan');
requires('Cache::Memcached');
requires('FindBin');
requires('Nagios::Plugin');
requires('Time::HiRes');

install_script "bin/check_memcached";

use_test_base;

auto_include;
auto_install;

WriteAll;
