use lib '.';
use inc::Module::Install;

perl_version 5.6;

RTx     'RT-Extension-FilterRules';
license 'gpl_2';
repository 'https://github.com/a-j-wood/rt-extension-filterrules';

requires_rt '4.2.0';
rt_too_new '5.2.0';

sign;
WriteAll;
