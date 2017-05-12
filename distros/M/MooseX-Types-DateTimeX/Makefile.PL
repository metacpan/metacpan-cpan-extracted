use inc::Module::Install;

name     'MooseX-Types-DateTimeX';
perl_version '5.008';
all_from 'lib/MooseX/Types/DateTimeX.pm';
author   'Evan Carroll <me@evancarroll.com>';
license  'perl';

requires 'Moose'              => '0.41'; # class_type
requires 'MooseX::Types'      => '0.04';
requires 'namespace::clean'   => '0.08';
requires 'Time::Duration::Parse' => '0.06';


requires 'MooseX::Types::DateTime::ButMaintained' => '0.04';

requires 'DateTimeX::Easy' => '0.085';

test_requires 'Test::use::ok'    => '0.02';
test_requires 'Test::Exception'  => '0.27';
test_requires 'Test::More';

repository 'git@github.com:EvanCarroll/mx-t-datetimex.git';

auto_install;

WriteAll;
