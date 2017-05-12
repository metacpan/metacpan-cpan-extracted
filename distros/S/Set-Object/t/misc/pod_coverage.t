#!perl

BEGIN {
    eval "use Test::Pod::Coverage tests => 2;";
    if ( $@ ) {
	require Test::More;
	Test::More::plan(skip_all => ("Test::Pod::Coverage required for "
			               ."testing POD coverage"));
	exit;
    }
}

use Set::Object;
use Set::Object::Weak;

pod_coverage_ok
    ( "Set::Object",
      { also_private => [ qr/^STORABLE_/, qr/^op_/,
			  "get_flat",
			  "rvrc", "rc", "is_object",
			], },
      "Set::Object, except the functions we know are private",
    );

pod_coverage_ok
    ( "Set::Object::Weak",
      { also_private => [ qr/^[A-Z_]+$/ ], },
      "Set::Object::Weak, with all-caps functions as privates",
    );
