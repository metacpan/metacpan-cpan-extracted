use inc::Module::Install;

name            ('POE-Component-DebugShell');
author          ('Matt Cashner (sungo@pobox.com)');
version_from    ('lib/POE/Component/DebugShell.pm');
license         ('bsd');

requires        ('perl' => 5.006001);
requires        ('POE'  => 1.0001);
requires        ('POE::Wheel::ReadLine');
requires        ('POE::API::Peek' => 0.02);
requires        ('Term::ReadKey');

requires        ('Test::More');
build_requires  ('Test::Distribution');
build_requires  ('Test::Pod::Coverage');


WriteAll();

