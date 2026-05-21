use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-ToggleTheme';
license 'gpl_2';
repository 'https://github.com/craigkai/rt-extension-toggletheme';

requires_rt '6.0.0';

sign;
WriteAll;
