use inc::Module::Install;

name            ('Spork-S5ThemeBlue');
abstract        ('Blue Theme for Spork::S5');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/Spork/S5ThemeBlue.pm');
requires        ('Spork::S5');
requires        ('Spork::S5Theme');
build_requires  ('Test::More');

&WriteAll;

