use inc::Module::Install;
use 5.008003;

RTx 'RT-Extension-PriorityAsString';
repository 'https://github.com/bestpractical/rt-extension-priorityasstring';

requires_rt '4.0.0';
rt_too_new '4.6.0';

no_index('package' => 'RT::Ticket');

sign;
WriteAll();
