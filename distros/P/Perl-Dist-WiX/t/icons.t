#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::IconArray;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 5;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $icon_1 = Perl::Dist::WiX::IconArray->new(
    trace  => 0,
);

ok( defined $icon_1, 'creating a P::D::W::IconArray' );
isa_ok( $icon_1, 'Perl::Dist::WiX::IconArray', 'The icons list was created correctly' );

is( $icon_1->as_string, q{}, '->as_string with no icons' );

$icon_1->add_icon('c:\testicon.ico');

is( $icon_1->search_icon('c:\testicon.ico'), 'testicon.msi.ico', '->search_icon' );

is( $icon_1->as_string, "    <Icon Id='I_testicon.msi.ico' SourceFile='c:\\testicon.ico' />\n", '->as_string' );
