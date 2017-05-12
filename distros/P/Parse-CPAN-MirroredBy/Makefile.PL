use inc::Module::Install 0.77;

all_from      'lib/Parse/CPAN/MirroredBy.pm';
requires      'IO::File'     => '1.13';
requires      'Params::Util' => '0.24';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.42';

WriteAll;
