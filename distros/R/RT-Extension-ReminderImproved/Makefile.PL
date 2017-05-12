use inc::Module::Install;

RTx 'RT-Extension-ReminderImproved', {deprecated_rt => 1};
repository 'https://github.com/cloos/RT-Extension-ReminderImproved';

requires_rt '3.8.0';
rt_too_new '4.0.0';

no_index package => 'RT::Reminders';
no_index package => 'RT::Ticket';

sign;
WriteAll;
