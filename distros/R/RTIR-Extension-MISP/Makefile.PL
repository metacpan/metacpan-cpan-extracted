use inc::Module::Install;

RTx     'RTIR-Extension-MISP', { remove_files => 1 };
license 'gpl_2';
repository 'https://github.com/bestpractical/rtir-extension-misp';

requires_rt '6.0.0';
rt_too_new '6.2.0';

requires 'UUID::Tiny';

sign;
WriteAll;
