use inc::Module::Install;

RTx('RT-Extension-ElapsedBusinessTime');
license_from('lib/RT/Extension/ElapsedBusinessTime.pm');

#githubmeta('github');

requires('Set::Object');
requires('Try::Tiny');

requires_rt '4.0.0';

recommends 'Dates::Holiday';

sign;
&WriteAll;
