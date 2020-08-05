use lib '.';
use inc::Module::Install;

RTx 'RT-Authen-Token';

requires_rt '4.2.5';
rt_too_new '4.6';

sign;
WriteAll;
