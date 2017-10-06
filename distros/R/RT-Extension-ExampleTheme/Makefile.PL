use inc::Module::Install;

RTx     'RT-Extension-ExampleTheme';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-exampletheme';

requires_rt '4.2.0';
rt_too_new '4.6.0';

WriteAll;
