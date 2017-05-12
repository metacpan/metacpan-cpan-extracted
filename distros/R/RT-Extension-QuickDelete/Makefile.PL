use inc::Module::Install;

RTx('RT-Extension-QuickDelete');
author ('Jesse Vincent <jesse@bestpractical.com>');
version_from ('lib/RT/Extension/QuickDelete.pm');
abstract_from('lib/RT/Extension/QuickDelete.pm');
readme_from('lib/RT/Extension/QuickDelete.pm');
license('perl');
requires('Test::More');

&WriteAll;
