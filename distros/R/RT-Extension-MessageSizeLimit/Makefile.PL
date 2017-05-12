use inc::Module::Install;

RTx('RT-Extension-MessageSizeLimit');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/MessageSizeLimit.pm');
abstract_from('lib/RT/Extension/MessageSizeLimit.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-MessageSizeLimit.git';

&WriteAll;
