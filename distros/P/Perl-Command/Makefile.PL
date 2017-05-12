use inc::Module::Install;

name            ('Perl-Command');
abstract        ('return a command for running Perl');
author          ('Sam Vilain <samv@cpan.org>');
version_from    ('lib/Perl/Command.pm');
license         ('perl');

requires        ('perl' => 5.006);
build_requires  ('Test::More');
#tests           ('mytest.pl');
sign		(1);

&WriteAll;
