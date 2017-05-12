use inc::Module::Install;

RTx 'RT-Extension-BriefHistory';

repository 'https://github.com/cloos/RT-Extension-BriefHistory';

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;
