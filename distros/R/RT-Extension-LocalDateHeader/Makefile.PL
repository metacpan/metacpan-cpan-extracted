use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-LocalDateHeader';

repository('https://github.com/bestpractical/rt-extension-localdateheader');

requires_rt '4.0.8';

sign;
WriteAll;
