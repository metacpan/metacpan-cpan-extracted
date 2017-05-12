use inc::Module::Install;

name 'Module-Install-Bundle-LocalLib';
all_from 'lib/Module/Install/Bundle/LocalLib.pm';
requires 'App::BundleDeps' => '0.00006';

auto_set_repository;

WriteAll;