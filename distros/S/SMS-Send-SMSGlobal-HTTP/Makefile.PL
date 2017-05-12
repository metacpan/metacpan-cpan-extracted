use inc::Module::Install;

name        'SMS-Send-SMSGlobal-HTTP';
module_name 'SMS::Send::SMSGlobal::HTTP';
all_from    'lib/SMS/Send/SMSGlobal/HTTP.pm';
author      q{David Warrring <david.warring@gmail.com>};
license     'perl';

requires (
    'Class::Accessor'       => 0,
    'fields'                => 0,
    'LWP::UserAgent'        => 0,
    'SMS::Send::Driver'     => 0,
    'HTTP::Request::Common' => 0,
    'Try::Tiny'             => 0,
    'Scalar::Util'          => 0,
    'parent'                => 0,
    );

recommends (
    );

test_requires (
    'Test::More'       => 0,
    'Test::NoWarnings' => 0,
    'Test::Fatal'      => 0,
    'Test::MockObject' => 0,
    'HTTP::Response'   => 0,
    );

auto_install;

#
# Module::Install::Repository magic
#
auto_set_repository();

WriteAll;

