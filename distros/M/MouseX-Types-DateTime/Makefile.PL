use inc::Module::Install;
name 'MouseX-Types-DateTime';
all_from 'lib/MouseX/Types/DateTime.pm';

requires 'Mouse' => '0.15';
requires 'MouseX::Types' => '0.01';
requires 'Scalar::Util';
requires 'namespace::clean';
requires 'DateTime';
requires 'DateTime::Duration';
requires 'DateTime::TimeZone';
requires 'DateTime::Locale';
requires 'DateTimeX::Easy';
requires 'Time::Duration::Parse';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'ok';
author_tests 'xt';
use_test_base;

auto_include_deps;
WriteAll;
