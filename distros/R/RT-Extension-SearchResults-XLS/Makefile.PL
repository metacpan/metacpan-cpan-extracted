use inc::Module::Install;

RTx('RT-Extension-SearchResults-XLS');
license('perl');
author('Emmanuel Lacour <elacour@home-dn.net>');
version_from('lib/RT/Extension/SearchResults/XLS.pm');
abstract_from('lib/RT/Extension/SearchResults/XLS.pm');
requires('Spreadsheet::WriteExcel');
repository 'git://git.home-dn.net/manu/RT-Extension-SearchResults-XLS.git';

&WriteAll;
