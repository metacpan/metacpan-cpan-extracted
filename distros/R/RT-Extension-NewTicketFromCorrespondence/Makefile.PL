use lib '.';
use inc::Module::Install;

perl_version 5.6;

RTx     'RT-Extension-NewTicketFromCorrespondence';
license 'gpl_3';
repository 'https://codeberg.org/a-j-wood/rt-extension-newticketfromcorrespondence';

requires_rt '4.2.0';
rt_too_new '5.2.0';

sign;
WriteAll;
