# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'PAR-Repository-Web';
all_from 'lib/PAR/Repository/Web.pm';

requires 'Catalyst::Runtime' => '5.7014';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::View::TT';
requires 'Template' => '2.20';
requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats

requires 'PAR::Repository::Query' => '0.13';
requires 'PAR::Repository::Client' => '0.18';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
