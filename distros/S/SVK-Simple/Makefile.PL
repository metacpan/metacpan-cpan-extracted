use inc::Module::Install;

name            ('SVK-Simple');
abstract        ('Simple SVK object loader');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/SVK/Simple.pm');
requires        (qw(
    Class::Field 0.12
    SVK          0.30
));

build_requires  ('Test::More');

&WriteAll;

