use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-QuickCalls';

requires_rt '4.0.0';
rt_too_new '5.2.0';

test_requires('Test::More');

&WriteAll;
