use inc::Module::Install;
RTx('RT-Extension-FormTools');
requires_rt('4.2.3');

repository('https://github.com/bestpractical/rt-extension-formtools');

sign();
WriteAll();

