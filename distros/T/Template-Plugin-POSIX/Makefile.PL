use strict;
use inc::Module::Install;

name            ('Template-Plugin-POSIX');
perl_version    ('5.004');
all_from        ('lib/Template/Plugin/POSIX.pm');

requires        ('POSIX');
requires        ('Template');
requires        ('Data::Dumper');

#build_requires  ('Test::Base' => '0.53');
use_test_base;

auto_install;
WriteAll;

