# -*- perl -*-

# t/001_basic.t - Optional core module - should be there!

use Test::More tests => 2;

package File::Spec::Functions::Dummy;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	canonpath
	catdir
	catfile
	curdir
	rootdir
	updir
	no_upwards
	file_name_is_absolute
	path
);

@EXPORT_OK = qw(
	devnull
	tmpdir
	splitpath
	splitdir
	catpath
	abs2rel
	rel2abs
	case_tolerant
);

%EXPORT_TAGS = ( ALL => [ @EXPORT_OK, @EXPORT ] );


sub curdir {
	die "Ouch! should be calling the one in F::S::F";
}

package main;
use strict;

BEGIN { use_ok( 'Module::Optional', 'File::Spec::Functions' ); }

#02
like(curdir(), qr/\.|\[\]/, "curdir returned something sensible");

