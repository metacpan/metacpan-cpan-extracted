use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-QuickCalls';
repository 'https://github.com/bestpractical/rt-extension-quickcalls';

requires_rt '6.0.0';
rt_too_new '6.2.0';

test_requires('Test::More');

sign;
&WriteAll;
