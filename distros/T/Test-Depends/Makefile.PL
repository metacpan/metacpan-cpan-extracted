use inc::Module::Install;

name            ('Test-Depends');
abstract        ('Gracefully skip tests if missing modules');
author          ('Sam Vilain <samv@cpan.org>');
version_from    ('lib/Test/Depends.pm');
license         ('perl');

requires        ('perl' => 5.006);
build_requires  ('Test::More');
#tests           ('mytest.pl');
sign		(1);

&WriteAll;
