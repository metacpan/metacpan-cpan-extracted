use inc::Module::Install 0.90;
use strict;
use warnings;

if ($Module::Install::AUTHOR) {
    require Module::Install::AuthorTests;
}

name 'MooseX-Types-IPv4';
all_from 'lib/MooseX/Types/IPv4.pm';

requires 'Moose';
requires 'MooseX::Types::Common';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'namespace::autoclean';

author_tests 't/author';

WriteAll();

