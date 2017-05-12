use inc::Module::Install;

name 'Plack-Middleware-ForceEnv';
all_from 'lib/Plack/Middleware/ForceEnv.pm';
license 'perl';

requires Plack => 0.9925;

auto_install;
WriteAll;
