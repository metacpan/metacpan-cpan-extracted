use inc::Module::Install;

all_from      'lib/Mirror/JSON.pm';
requires      'Params::Util' => '0.10';
requires      'JSON'         => '2.09';
requires      'URI'          => '1.28';
requires      'Time::HiRes'  => 0;
requires      'Time::Local'  => '1.13';
requires      'LWP::Simple'  => 0;
test_requires 'Test::More'   => '0.42';
test_requires 'LWP::Online'  => '0.03';

WriteAll;
