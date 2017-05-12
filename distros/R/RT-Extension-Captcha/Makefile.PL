use inc::Module::Install;

RTx 'RT-Extension-Captcha';

requires_rt '4.2.0';
requires 'GD::SecurityImage';

repository 'https://github.com/bestpractical/rt-extension-captcha';

sign();
WriteAll();
