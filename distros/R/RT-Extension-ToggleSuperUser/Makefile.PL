use inc::Module::Install;

RTx('RT-Extension-ToggleSuperUser');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version('0.02');
abstract_from('lib/RT/Extension/ToggleSuperUser.pm');

&WriteAll;

