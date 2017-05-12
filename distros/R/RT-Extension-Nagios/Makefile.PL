use inc::Module::Install;

RTx('RT-Extension-Nagios');

repository('https://github.com/bestpractical/rt-extension-nagios');

sign();
WriteAll();
