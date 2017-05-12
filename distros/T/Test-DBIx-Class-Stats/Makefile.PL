use strict;
use warnings;
use inc::Module::Install;

name        'Test-DBIx-Class-Stats';
all_from    'lib/Test/DBIx/Class/Stats.pm';

license     'perl';
author      'osfameron';

requires      'DBIx::Class';
requires      'Moo';
requires      'MooX::HandlesVia';
requires      'Time::HiRes';
requires      'Test::More' => 0.42;
requires      'Test::Builder' => 1.001004_001; # https://github.com/Test-More/test-more/pull/395

author_requires 'Test::CPAN::Changes' => 0.400002;
author_tests 'xt';

test_requires 'Test::DBIx::Class';

auto_install;
WriteAll;
