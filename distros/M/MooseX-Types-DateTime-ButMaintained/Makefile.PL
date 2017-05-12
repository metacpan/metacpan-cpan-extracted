use inc::Module::Install;

name     'MooseX-Types-DateTime-ButMaintained';
all_from 'lib/MooseX/Types/DateTime/ButMaintained.pm';
author   'Evan Carroll <me@evancarroll.com>';
license  'perl';

requires 'Moose'              => '0.41'; # class_type
requires 'MooseX::Types'      => '0.30';
requires 'namespace::autoclean';

# Datetime stuff
requires 'DateTime'           => '0.4302';
requires 'DateTime::Locale'   => '0.4001';

## DT:TZ broke 0.92 until .95, going to require latest at .96
requires 'DateTime::TimeZone' => '0.96';
requires 'Olson::Abbreviations' => '0.03';

test_requires 'Test::Exception'  => '0.27';
test_requires 'Test::More';
test_requires 'Test::use::ok'    => '0.02';

repository 'git://github.com/EvanCarroll/mx-t-datetime-butmainted.git';
homepage   'http://www.evancarroll.com';

auto_install;

WriteAll;
