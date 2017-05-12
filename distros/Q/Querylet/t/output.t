use Test::More tests => 8;
use strict;
use warnings;

BEGIN {
	    use_ok("Querylet::Query");
	require_ok("Querylet::Output");
}

eval { Querylet::Output->default_type };
like($@, qr/unimplemented/, "death on abstract base method");

eval { Querylet::Output->handler };
like($@, qr/unimplemented/, "death on abstract base method");

package QOBogus;
	our @ISA = qw(Querylet::Output);
	sub default_type { 'bogus' }
	sub handler      {
		our $handler_method_called++;
		sub { }
	}
package main;


is(QOBogus->default_type,        'bogus', 'default_type method');
is($QOBogus::handler_method_called, undef, 'handler unregistered');

QOBogus->import;
is($QOBogus::handler_method_called,     1, 'handler registered (default name)');

QOBogus->import('fake');
is($QOBogus::handler_method_called,     2, 'handler registered (new name)');

