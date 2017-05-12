#!perl

use strict;
use warnings;

use Test::More tests => 1;

SKIP: {
    if (eval { require Module::Signature; 1 }) {
	ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
	    => "Valid signature" );
    }
    else {
	diag("Next time around, consider install Module::Signature,\n".
	     "so you can verify the integrity of this distribution.\n");
	skip("Module::Signature not installed", 1)
    }
}

__END__
