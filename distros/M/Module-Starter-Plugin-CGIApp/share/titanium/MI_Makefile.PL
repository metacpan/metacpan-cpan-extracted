use inc::Module::Install;

name         '<tmpl_var distro>';
all_from     '<tmpl_var main_pm_file>';
author       '<tmpl_var author>';
license      '<tmpl_var license>';
perl_version '5.008';

build_requires 'Test::More'                    => 0;
build_requires 'Test::WWW::Mechanize::CGIApp'  => 0;
requires       'Titanium'                      => 0;
requires       'HTML::Template'                => 0;
install_share;
auto_install;
sign 1;

WriteAll;

