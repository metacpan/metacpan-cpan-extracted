use inc::Module::Install;

name     'SMS-Send-Wadja';
all_from 'lib/SMS/Send/Wadja.pm';
author   'Dan Dascalescu <dandv@cpan.org>';
license  'perl';

requires(
    'SMS::Send::Driver'     => 0,
    'HTTP::Request::Common' => 0,
    'LWP::UserAgent'        => 0,
    'DateTime'              => 0,  # for delivery reports
);

test_requires 'Test::More';

auto_install;

WriteAll;
