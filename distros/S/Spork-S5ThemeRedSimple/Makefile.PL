use inc::Module::Install;

name            ('Spork-S5ThemeRedSimple');
abstract        ('A Simplistic Red Theme For Spork-S5');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Spork/S5ThemeRedSimple.pm');
requires        ('Spork::S5');
build_requires  ('Test::More');

&WriteAll;

