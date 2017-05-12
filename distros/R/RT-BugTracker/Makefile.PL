use inc::Module::Install;

RTx('RT-BugTracker');

repository('https://github.com/bestpractical/rt-bugtracker');

requires_rt('4.0.9');
rt_too_new('4.2.0');

no_index( package => 'RT::Queue' );

sign();
WriteAll();
