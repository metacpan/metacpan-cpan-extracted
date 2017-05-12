use inc::Module::Install;

RTx         'RT-Extension-ArticleTemplates';

repository('https://github.com/bestpractical/rt-extension-articletemplates');

requires_rt('4.0.0');

build_requires 'Test::More';

no_index('package' => 'RT::Article');

sign;
auto_install;
WriteAll;

