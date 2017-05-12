use inc::Module::Install;

RTx('RT-Extension-MandatorySubject');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version('0.03');
abstract_from('lib/RT/Extension/MandatorySubject.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-MandatorySubject.git';

&WriteAll;

