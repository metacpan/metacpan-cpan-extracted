use inc::Module::Install;

RTx     'RT-Extension-AssetAutoName';
license 'gpl_2';
repository 'https://github.com/catalyst-cloud/rt-extension-assetautoname';

requires_rt '4.4.0';
rt_too_new '4.6.0';

sign;
WriteAll;
