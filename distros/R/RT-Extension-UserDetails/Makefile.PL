use inc::Module::Install;

RTx('RT-Extension-UserDetails');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/UserDetails.pm');
abstract_from('lib/RT/Extension/UserDetails.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-UserDetails.git';

&WriteAll;

