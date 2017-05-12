#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Perl::Dist::Inno::Registry;





#####################################################################
# Main Tests

my $registry1 = Perl::Dist::Inno::Registry->env( TERM => 'dumb' );
isa_ok( $registry1, 'Perl::Dist::Inno::Registry' );
is( $registry1->root,       'HKLM', '->source ok' );
is( $registry1->subkey,     'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', '->subkey ok' );
is( $registry1->value_type, 'expandsz', '->value_type ok' );
is( $registry1->value_name, 'TERM', '->value_name ok' );
is( $registry1->value_data, 'dumb', '->value_data ok' );
is(
	$registry1->as_string,
	'Root: HKLM; Subkey: SYSTEM\CurrentControlSet\Control\Session Manager\Environment; ValueType: expandsz; ValueName: TERM; ValueData: "dumb"',
	'->as_string ok',
);
