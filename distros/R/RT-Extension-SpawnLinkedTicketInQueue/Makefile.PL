use inc::Module::Install;

RTx 'RT-Extension-SpawnLinkedTicketInQueue';

repository 'https://github.com/bestpractical/rt-extension-spawnlinkedticketinqueue';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign();
WriteAll();

