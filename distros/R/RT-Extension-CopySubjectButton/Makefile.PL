use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-CopySubjectButton';
license 'gpl_2';
repository 'https://github.com/averkios/RT-Extension-CopySubjectButton';

requires_rt '5.0.1';
rt_too_new '5.2.0';

sign;
WriteAll;
