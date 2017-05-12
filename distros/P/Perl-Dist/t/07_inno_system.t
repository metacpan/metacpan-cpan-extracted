#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use File::Spec::Functions ':ALL';
use Perl::Dist::Inno::System;





#####################################################################
# Main Tests

my $object = Perl::Dist::Inno::System->run(
	filename    => "{app}\\perl\\bin\\program",
	working_dir => "{app}\\perl\\bin",
);
isa_ok( $object, 'Perl::Dist::Inno::System' );
is( $object->section, 'Run', '->section is Run' );
is( $object->filename, "{app}\\perl\\bin\\program", '->filename ok' );
is( $object->working_dir, "{app}\\perl\\bin", '->working_dir ok' );
is( $object->description, undef, '->description undef' );
is(
	$object->as_string,
	"Filename: \"{app}\\perl\\bin\\program\"; WorkingDir: \"{app}\\perl\\bin\"",
	'->as_string ok',
);
