use inc::Module::Install;

name            ('Template-Plugin-RoundRobin');
abstract        ('Server data in a round robin manner.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Template/Plugin/RoundRobin.pm');
requires        (
    Template => 0,
    'Data::RoundRobin' => 0
    );
build_requires  ('Test::More');

&auto_install;
&WriteAll;

