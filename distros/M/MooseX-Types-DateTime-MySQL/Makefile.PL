use strict;
use warnings;
use inc::Module::Install 0.98;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'MooseX-Types-DateTime-MySQL';
all_from 'lib/MooseX/Types/DateTime/MySQL.pm';

requires 'MooseX::Types';
requires 'namespace::clean';
requires 'MooseX::Types::DateTime' => '0.05';
requires 'DateTime::Format::MySQL';
requires 'DateTime::Format::Duration';

build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://github.com/bobtfish/moosex-types-datetime-mysql.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/MooseX/Types/DateTime/MySQL.pm > README")
        and die $!;
}

WriteAll();
