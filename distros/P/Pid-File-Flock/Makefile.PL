use inc::Module::Install;

name      'Pid-File-Flock';
license   'perl';
all_from  'lib/Pid/File/Flock.pm';

test_requires 'Test::More';

auto_install;

WriteAll;

