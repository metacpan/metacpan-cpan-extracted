#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use CurieTestHelper;
use Renard::Curie::Setup;

use Renard::Curie::Helper;
use Function::Parameters;

subtest "Use helper functions" => fun {
	my $val = Renard::Curie::Helper->gval(int => 512);
	isa_ok( $val, 'Glib::Object::Introspection::GValueWrapper' );

	my $enum = Renard::Curie::Helper->genum(
		'Gtk3::PackType' => 'GTK_PACK_START' );
	is( $enum, 0 );
};
