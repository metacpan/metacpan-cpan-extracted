use inc::Module::Install;

RTx('RT-Extension-ReassignOwner');
author_from('lib/RT/Extension/ReassignOwner.pm');
version_from ('lib/RT/Extension/ReassignOwner.pm');
abstract_from('lib/RT/Extension/ReassignOwner.pm');
license('perl');
requires('Test::More');

&WriteAll;
