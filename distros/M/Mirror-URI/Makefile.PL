use inc::Module::Install 0.91;

all_from      'lib/Mirror/URI.pm';
requires      'Params::Util'      => '1.00';
requires      'Parse::CPAN::Meta' => '1.39';
requires      'JSON'              => '2.13';
requires      'URI'               => '1.28';
requires      'Time::HiRes'       => '1.9714';
requires      'Time::Local'       => '1.13';
requires      'LWP::Simple'       => '1.41';
test_requires 'Test::More'        => '0.42';
test_requires 'File::Temp'        => '0.19';
test_requires 'LWP::Online'       => '1.07';

WriteAll;
