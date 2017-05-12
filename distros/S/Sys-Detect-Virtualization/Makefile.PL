use inc::Module::Install;

name     'Sys-Detect-Virtualization';
all_from 'lib/Sys/Detect/Virtualization.pm';
author   q{Dave O'Neill <dmo@roaringpenguin.com>};
license  'perl';

requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'POSIX';
recommends 'Parse::DMIDecode' => '0.03';

test_requires 'Test::More'  => '0.82';
test_requires 'Test::Deep';
test_requires 'Test::Exception';
test_requires 'File::Spec';

install_script 'script/virtdetect';

WriteAll;

