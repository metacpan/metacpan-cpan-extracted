use inc::Module::Install;

name 'Plack-Middleware-SetEnvFromHeader';
all_from 'lib/Plack/Middleware/SetEnvFromHeader.pm';
readme_from 'lib/Plack/Middleware/SetEnvFromHeader.pm';
license 'perl';

requires Plack => 0.9925;

auto_install;
WriteAll;
