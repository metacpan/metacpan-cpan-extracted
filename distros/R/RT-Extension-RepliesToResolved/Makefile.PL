use lib '.';
use inc::Module::Install;
RTx('RT-Extension-RepliesToResolved');

repository('https://github.com/bestpractical/rt-extension-repliestoresolved');

no_index( package => 'RT::Interface::Email' );

requires_rt '4.0.9';
rt_too_new  '6.2.0';

license 'gplv2';

sign();
WriteAll();
