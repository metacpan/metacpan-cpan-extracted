use inc::Module::Install;

RTx('RT-SimpleGPGVerify');
license('GPLv2');
requires('Mail::GnuPG');
author('Jesse Vincent <jesse@bestpractical.com>');

&WriteAll;
