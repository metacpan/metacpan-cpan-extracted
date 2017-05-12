use inc::Module::Install;

RTx     'RT-Extension-TimeTracking-Automatic';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-timetracking-automatic';

requires_rt '4.2.0';
rt_too_new '4.6.0';

sign;
WriteAll;
