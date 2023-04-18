use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-CipherMailHeaders';
license 'gpl_2';
repository 'https://github.com/certat/rt-extension-ciphermailheaders';

requires_rt '4.4.0';
rt_too_new '5.2.0';

sign;
WriteAll;
