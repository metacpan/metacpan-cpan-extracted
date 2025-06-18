use lib '.';
use inc::Module::Install;

RTx('RT-Extension-ActivityReports');
license('perl');
requires('Time::Duration');

requires_rt '6.0.0';
rt_too_new '6.2.0';

sign;
&WriteAll;
