use inc::Module::Install;

RTx('RT-OnlineDocs');

requires_rt('4.0.0');
rt_too_new('4.2.0');

requires('Pod::Simple::HTML');
requires('File::Basename');
requires('File::Find');
requires('File::Temp');
requires('File::Spec');
auto_install();

repository('https://github.com/bestpractical/rt-onlinedocs');

sign();
WriteAll();
