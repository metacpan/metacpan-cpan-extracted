use strict;
use inc::Module::Install;
my $astt = "script/astt.pl";

name            ('Template-Ast');
version_from    ('lib/Template/Ast.pm');
abstract       ( 'Handling Perl AST used with Perl Template Toolkit' );
author          ('Agent Zhang <agent2002@126.com>');
license         ('perl');
install_script  ($astt);
requires        ('Data::Dumper');
build_requires  ('Test::More');
build_requires  ('File::Compare');

&WriteAll;
