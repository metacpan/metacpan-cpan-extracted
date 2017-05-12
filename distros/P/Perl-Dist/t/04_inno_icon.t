#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 10;
use File::Spec::Functions ':ALL';
use Perl::Dist::Inno::Icon;





#####################################################################
# Main Tests

my $icon1 = Perl::Dist::Inno::Icon->new(
	name        => '{group}\{cm:UninstallProgram,Strawberry Perl}',
	filename    => '{uninstallexe}',
);
isa_ok( $icon1, 'Perl::Dist::Inno::Icon' );
is( $icon1->name,        '{group}\{cm:UninstallProgram,Strawberry Perl}', '->name ok' );
is( $icon1->filename,    '{uninstallexe}', '->filename ok' );
is( $icon1->working_dir, undef, '->working_dir ok' );
is(
	$icon1->as_string,
	'Name: "{group}\{cm:UninstallProgram,Strawberry Perl}"; Filename: "{uninstallexe}"',
	'->as_string ok',
);

my $icon2 = Perl::Dist::Inno::Icon->new(
	name        => '{group}\Install modules with CPAN.pm',
	filename    => '{app}\perl\bin\cpan.bat',
	working_dir => '{app}\perl',
);
isa_ok( $icon2, 'Perl::Dist::Inno::Icon' );
is( $icon2->name,        '{group}\Install modules with CPAN.pm', '->name ok' );
is( $icon2->filename,    '{app}\perl\bin\cpan.bat', '->filename ok' );
is( $icon2->working_dir, '{app}\perl', '->working_dir ok' );
is(
	$icon2->as_string,
	'Name: "{group}\Install modules with CPAN.pm"; Filename: "{app}\perl\bin\cpan.bat"; WorkingDir: "{app}\perl"',
	'->as_string ok',
);
