use inc::Module::Install;

RTx('RT-Integration-SVN');
license('GPLv2');
version_from('lib/RT/Integration/SVN.pm');
build_requires('Module::Install::RTx' => 0.08);
author('Jesse Vincent <jesse@bestpractical.com>');

&WriteAll;
