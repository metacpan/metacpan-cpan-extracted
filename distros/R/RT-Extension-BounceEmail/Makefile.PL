use inc::Module::Install;

RTx     'RT-Extension-BounceEmail';
license 'gplv2';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign;
WriteAll;
