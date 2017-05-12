use inc::Module::Install;

name            ('Spork-S5');
abstract        ('Write S5 slide with Spork syntax.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Spork/S5.pm');
requires        (Spork => '0.20');
build_requires  ('Test::More');

&WriteAll;

