use inc::Module::Install;

RTx 'RT-Extension-LifecycleUI';

requires_rt_plugin 'RT::Extension::ConfigInDatabase';

requires_rt '4.4';
rt_too_new '4.6';

WriteAll;
sign;
