use inc::Module::Install;

RTx     'RTIR-Extension-MISP';
license 'gpl_2';
repository 'https://github.com/bestpractical/rtir-extension-misp';

requires_rt '5.0.0';
rt_too_new '5.2.0';

requires 'UUID::Tiny';

sign;
WriteAll;
