use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-QuickAssign';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-quickassign';

requires_rt '4.0.0';

sign;
WriteAll;
