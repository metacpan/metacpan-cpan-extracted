use inc::Module::Install;
use strict;
use warnings;
name 'MooseX-Types-Email-Loose';
all_from 'lib/MooseX/Types/Email/Loose.pm';

requires 'Email::Valid::Loose';
requires 'Moose';
requires 'MooseX::Types::Common';
requires 'MooseX::Types::Email';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'namespace::autoclean';

tests 't/*.t';

auto_set_repository;
auto_include;

WriteAll;
