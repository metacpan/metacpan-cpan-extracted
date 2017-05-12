use inc::Module::Install 0.77;

all_from      'lib/SMS/Send/AU/MyVodafone.pm';
requires      'Carp'            => 0;
requires      'SMS::Send'       => '0.02';
requires      'WWW::Mechanize'  => '1.06';
requires      'IO::Socket::SSL' => '0.97';
requires      'LWP'             => '5.69';
test_requires 'Test::More'      => '0.47';

WriteAll;
