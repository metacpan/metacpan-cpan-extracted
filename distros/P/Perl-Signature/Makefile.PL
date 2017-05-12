use inc::Module::Install 0.77;

all_from      'lib/Perl/Signature.pm';
requires      'Storable'      => '2.11';
requires      'Digest::MD5'   => '2.30';
requires      'Config::Tiny'  => '2.00';
requires      'PPI'           => '1.109';
test_requires 'Test::More'    => '0.47';
test_requires 'File::Spec'    => '0.80';
test_requires 'File::Copy'    => 0;

WriteAll;
