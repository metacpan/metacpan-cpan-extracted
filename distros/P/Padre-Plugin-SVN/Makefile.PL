use inc::Module::Install;

name 'Padre-Plugin-SVN';
all_from 'lib/Padre/Plugin/SVN.pm';
author 'Gabor Szabo <szabgab@gmail.com>';
license 'perl';


requires 'Padre' => '0.27';

# SVN::Class was patched at 0.15 to use the --file option
# allowing for multi-line commit messages.
requires 'SVN::Class' => '0.15';


build_requires 'Test::More';

# what is this??
#is_padre_plugin;

auto_install;

WriteAll;

