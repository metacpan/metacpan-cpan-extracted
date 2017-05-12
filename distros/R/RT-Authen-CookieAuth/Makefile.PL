use inc::Module::Install;

RTx('RT-Authen-CookieAuth');

license('GPL version 2');
author('Mike Peachey <zordrak@cpan.org>');

all_from('lib/RT/Authen/CookieAuth.pm');

requires('RT');
requires('RT::Authen::ExternalAuth');

&WriteAll;
