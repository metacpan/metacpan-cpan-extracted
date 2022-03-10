use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-SelfServiceSimpleSearch';

repository('https://github.com/bestpractical/rt-extension-selfservicesimplesearch');

sign;
WriteAll;
