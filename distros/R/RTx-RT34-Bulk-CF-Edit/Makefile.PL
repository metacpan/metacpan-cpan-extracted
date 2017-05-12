use inc::Module::Install;

RTx('RTx-RT34-Bulk-CF-Edit');
author ('Alex Vandiver <alexmv@bestpractical.com>');
version_from ('lib/RTx/RT34/Bulk/CF/Edit.pm');
abstract_from('lib/RTx/RT34/Bulk/CF/Edit.pm');
license('perl');
requires('Test::More');

&WriteAll;
