use lib '.';
use inc::Module::Install;

perl_version 5.6;

RTx     'RT-Extension-TOTPMFA';
license 'gpl_3';
repository 'https://codeberg.org/ivarch/rt-extension-totpmfa';

requires('Authen::OATH');
requires('Convert::Base32');
requires('Imager::QRCode');
requires('Crypt::CBC');
requires('LWP::UserAgent');

requires_rt '5.0.0';
rt_too_new '5.2.0';

sign;
WriteAll;
