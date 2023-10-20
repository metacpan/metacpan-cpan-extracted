use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-QuickCalls';
repository 'https://github.com/bestpractical/rt-extension-quickcalls';

requires_rt '4.4.0';
rt_too_new '5.2.0';

test_requires('Test::More');

sign;
&WriteAll;
