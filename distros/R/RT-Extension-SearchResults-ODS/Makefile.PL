use inc::Module::Install;

RTx('RT-Extension-SearchResults-ODS');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/SearchResults/ODS.pm');
abstract_from('lib/RT/Extension/SearchResults/ODS.pm');
requires('OpenOffice::OODoc');
repository 'git://git.home-dn.net/manu/RT-Extension-SearchResults-ODS.git';

&WriteAll;

