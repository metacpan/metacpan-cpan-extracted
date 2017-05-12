use Test::More tests => 8;
use strict;
use warnings;

BEGIN {
	    use_ok("Querylet::Query");
	require_ok("Querylet::Input");
}

eval { Querylet::Input->default_type };
like($@, qr/unimplemented/, "death on abstract base method");

eval { Querylet::Input->handler };
like($@, qr/unimplemented/, "death on abstract base method");

package QIBogus;
	our @ISA = qw(Querylet::Input);
	sub default_type { 'bogus' }
	sub handler      {
		our $handler_method_called++;
		sub { }
	}
package main;


is(QIBogus->default_type,         'bogus', 'default_type method');
is($QIBogus::handler_method_called, undef, 'handler unregistered');

QIBogus->import;
is($QIBogus::handler_method_called,     1, 'handler registered (default name)');

QIBogus->import('fake');
is($QIBogus::handler_method_called,     2, 'handler registered (new name)');

