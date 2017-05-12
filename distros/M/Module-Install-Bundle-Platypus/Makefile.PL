use inc::Module::Install;

name 'Module-Install-Bundle-Platypus';
all_from 'lib/Module/Install/Bundle/Platypus.pm';
requires 'App::BundleDeps';

WriteAll;