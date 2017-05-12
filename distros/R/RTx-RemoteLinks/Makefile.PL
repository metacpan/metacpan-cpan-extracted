use inc::Module::Install;

RTx 'RTx-RemoteLinks';

repository 'https://github.com/bestpractical/rtx-remotelinks';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign;
WriteAll;
