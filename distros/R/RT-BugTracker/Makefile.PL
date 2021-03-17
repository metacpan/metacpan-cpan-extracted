use lib '.';
use inc::Module::Install;

RTx('RT-BugTracker');

repository('https://github.com/bestpractical/rt-bugtracker');

requires_rt('5.0.0');
rt_too_new('5.2.0');

no_index( package => 'RT::Queue' );

WriteAll();
