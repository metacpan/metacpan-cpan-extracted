use inc::Module::Install;

RTx('RT-View-ConciseSpreadsheet');
author ('Jesse Vincent <jesse@bestpractical.com>');
version_from ('lib/RT/View/ConciseSpreadsheet.pm');
abstract_from('lib/RT/View/ConciseSpreadsheet.pm');
license('perl');
requires('Test::More');
requires('Text::CSV_XS');

&WriteAll;
