use lib ".";
use inc::Module::Install;

RTx('RT-BugTracker-Public');

requires_rt('5.0.0');
rt_too_new('5.2.0');

WriteAll();
