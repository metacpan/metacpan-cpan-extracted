use inc::Module::Install;

RTx 'RT-Extension-RightsInspector';

requires_rt '4.4';
rt_too_new '4.6';

WriteAll;
sign;
