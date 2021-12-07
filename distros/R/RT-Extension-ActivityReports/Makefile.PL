use lib '.';
use inc::Module::Install;

RTx('RT-Extension-ActivityReports');
license('perl');
requires('Time::Duration');

requires_rt '4.0.0';
rt_too_new '5.2.0';

sign;
&WriteAll;
