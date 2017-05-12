use inc::Module::Install 0.77;

all_from      'lib/PITA/Test/Image/Qemu.pm';
requires      'File::ShareDir' => '1.00';
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';
install_share;

WriteAll;
