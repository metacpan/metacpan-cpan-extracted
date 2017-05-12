use inc::Module::Install;
name('RunApp');
version_from('lib/RunApp.pm');
requires('Template'     => '0'),
requires('YAML'         => '0');
requires('App::Control' => '0');

include('ExtUtils::AutoInstall');
auto_install();

WriteAll;
