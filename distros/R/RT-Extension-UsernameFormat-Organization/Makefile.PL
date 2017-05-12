use inc::Module::Install;

RTx 'RT-Extension-UsernameFormat-Organization';

requires_rt '4.2.0';
rt_too_new '4.4.0';

no_index package => 'RT::User';

sign;
WriteAll;
