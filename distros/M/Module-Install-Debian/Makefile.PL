use inc::Module::Install;

name          'Module-Install-Debian';
all_from      'lib/Module/Install/Debian.pm';
test_requires 'File::chdir';
test_requires 'File::Spec';
test_requires 'File::Copy';
test_requires 'File::Remove';
test_requires 'File::Temp';
test_requires 'Test::Pod::Coverage' => '1.04';
test_requires 'Test::Perl::Critic';
test_requires 'Test::Pod' => '1.14';

WriteAll;

