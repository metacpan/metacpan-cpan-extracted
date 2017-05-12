use inc::Module::Install;

# Module Install necessary modules

use Module::Install::Repository;
use Module::Install::ReadmeFromPod;
use Module::Install::CPANfile;

name 'Plack-Middleware-File-Less';
all_from 'lib/Plack/Middleware/File/Less.pm';
readme_from 'lib/Plack/Middleware/File/Less.pm';

auto_include_deps;
auto_set_repository;
cpanfile;
WriteAll;
