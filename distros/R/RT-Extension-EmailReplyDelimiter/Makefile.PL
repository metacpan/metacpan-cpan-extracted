use lib '.';
use inc::Module::Install;

perl_version 5.6;

RTx     'RT-Extension-EmailReplyDelimiter';
license 'gpl_3';
repository 'https://codeberg.org/ivarch/rt-extension-emailreplydelimiter';

requires_rt '4.2.0';
rt_too_new '6.0.3';

sign;
WriteAll;
