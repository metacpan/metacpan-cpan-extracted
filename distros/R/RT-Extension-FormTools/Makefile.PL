use inc::Module::Install;
RTx('RT-Extension-FormTools');
requires_rt('5.0.0');

repository('https://github.com/bestpractical/rt-extension-formtools');

sign();
WriteAll();

