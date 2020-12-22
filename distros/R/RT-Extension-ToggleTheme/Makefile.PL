use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-ToggleTheme';
license 'gpl_2';
repository 'https://github.com/craigkai/rt-extension-toggletheme';

requires_rt '5.0.0';
rt_too_new '5.2.0';

sign;
WriteAll;
