use inc::Module::Install;

RTx 'RT-Extension-AnnounceSimple';
repository 'https://github.com/cloos/RT-Extension-AnnounceSimple';

requires_rt '4.2.0';
rt_too_new '4.6.0';

sign;
WriteAll;
