use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-TerminalTheme';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-terminaltheme';

requires_rt '5.0.0';
rt_too_new '6.0.0';

sign;
WriteAll;
