#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Perl::Dist::Inno::File;





#####################################################################
# Main Tests

my $file1 = Perl::Dist::Inno::File->new(
	source             => 'dmake\*',
	dest_dir           => '{app}\dmake',
	recurse_subdirs    => 1,
	create_all_subdirs => 1,
);
isa_ok( $file1, 'Perl::Dist::Inno::File' );
is( $file1->source, 'dmake\*', '->source ok' );
is( $file1->dest_dir, '{app}\dmake', '->dest_dir ok' );
is( $file1->ignore_version, 1, '->ignore_version ok' );
is( $file1->recurse_subdirs, 1, '->recurse_subdirs ok' );
is( $file1->create_all_subdirs, 1, '->create_all_subdirs ok' );
is(
	$file1->as_string,
	'Source: "dmake\*"; DestDir: "{app}\dmake"; Flags: ignoreversion recursesubdirs createallsubdirs',
	'->as_string ok',
);
