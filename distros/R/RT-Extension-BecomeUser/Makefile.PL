use inc::Module::Install;

RTx     'RT-Extension-BecomeUser';
license 'gplv2';
repository 'https://github.com/maettu/RT-Extension-BecomeUser';

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;
