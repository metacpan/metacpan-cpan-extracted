use inc::Module::Install;

name            'REST-Client';
all_from        'lib/REST/Client.pm';

requires 'URI' => 0;
requires 'LWP::UserAgent' => 0;
requires 'LWP::Protocol::https' => '0';
test_requires 'Test::More' => '0.8';

WriteAll();
