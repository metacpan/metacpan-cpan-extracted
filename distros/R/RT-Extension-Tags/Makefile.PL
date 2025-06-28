use lib '.';
use inc::Module::Install;

RTx('RT-Extension-Tags', { remove_files => 1 });
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-tags';

requires_rt '6.0.0';
rt_too_new '6.2.0';

sign;
WriteAll;
