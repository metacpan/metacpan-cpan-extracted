use lib '.';
use inc::Module::Install;

RTx('RT-Extension-Captcha', { remove_files => 1 });

requires_rt '6.0.0';
requires 'Captcha::reCAPTCHA::V3';

repository 'https://github.com/bestpractical/rt-extension-captcha';

sign();
WriteAll();
