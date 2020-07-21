use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-Tags';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-tags';

requires_rt '4.0.0';
rt_too_new '5.2.0';

sign;
WriteAll;
