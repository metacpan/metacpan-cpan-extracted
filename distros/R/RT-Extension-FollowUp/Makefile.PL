use inc::Module::Install;

RTx('RT-Extension-FollowUp');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version('0.01');
abstract_from('lib/RT/Extension/FollowUp.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-FollowUp.git';

&WriteAll;

