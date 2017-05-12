use inc::Module::Install;

RTx('RT-Extension-AttachmentFilter');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/AttachmentFilter.pm');
abstract_from('lib/RT/Extension/AttachmentFilter.pm');
repository 'git://git.home-dn.net/manu/RT-Extension-AttachmentFilter.git';

&WriteAll;
