use strict;
use inc::Module::Install;

name            ('Template-Plugin-Perl');
perl_version    ('5.004');
all_from        ('lib/Template/Plugin/Perl.pm');

requires        ('Template');
requires        ('Data::Dumper');

#build_requires  ('Test::Base' => '0.53');
use_test_base;

auto_install;
WriteAll;

