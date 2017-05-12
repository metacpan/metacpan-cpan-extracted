use inc::Module::Install;

RTx     'RT-Extension-IncrementPriority';
license 'gplv2';
repository 'https://github.com/jrandall/rt-extension-incrementpriority';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign;
WriteAll;
