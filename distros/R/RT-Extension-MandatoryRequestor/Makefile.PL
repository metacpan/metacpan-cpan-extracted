use inc::Module::Install;

RTx('RT-Extension-MandatoryRequestor');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version('0.02');
abstract_from('lib/RT/Extension/MandatoryRequestor.pm');

&WriteAll;

