use inc::Module::Install;

RTx     'RT-Extension-OneClickClose';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-oneclickclose';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign;
WriteAll;
