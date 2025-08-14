use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-AI';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-ai';

requires_rt '6.0.0';
rt_too_new '6.2.0';

sign;
WriteAll;
