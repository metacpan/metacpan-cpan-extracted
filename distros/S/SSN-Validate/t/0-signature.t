#!/usr/bin/perl

use strict;
use Test::More tests => 1;

exit ok(1); # not yet

SKIP: {
    if (!eval { require Module::Signature; 1 }) {
	skip("Next time around, consider install Module::Signature, ".
	     "so you can verify the integrity of this distribution with
'cpansign'", 1);
    }
    elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') })
{
	skip("Cannot connect to the keyserver", 1);
    }
    else {
	ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
	    => "Valid signature" );
    }
}

__END__
