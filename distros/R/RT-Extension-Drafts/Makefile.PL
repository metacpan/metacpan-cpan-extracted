use inc::Module::Install;

RTx('RT-Extension-Drafts');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/Drafts.pm');
abstract_from('lib/RT/Extension/Drafts.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-Drafts.git';

&WriteAll;
