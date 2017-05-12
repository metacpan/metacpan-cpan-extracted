use inc::Module::Install;

RTx('RT-BugTracker-Public');

requires_rt('4.0.0');
rt_too_new('4.2.0');

sign();
WriteAll();
