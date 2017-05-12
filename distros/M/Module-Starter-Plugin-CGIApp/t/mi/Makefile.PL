use inc::Module::Install;

name         'Example-Dist';
all_from     'lib/Foo/Bar.pm';
author       'Jaldhar H. Vyas';
license      'perl';
perl_version '5.008';

build_requires 'Test::More'                    => 0;
build_requires 'Test::WWW::Mechanize::CGIApp'  => 0;
requires       'CGI::Application'              => 4.04;
requires       'HTML::Template'                => 0;
install_share;
auto_install;
sign 1;

WriteAll;

