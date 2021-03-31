use inc::Module::Install;
use lib '.';

RTx     'RT-Extension-HelpDesk';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-helpdesk';

requires_rt '5.0.0';
rt_too_new '5.2.0';

sign;
WriteAll;
