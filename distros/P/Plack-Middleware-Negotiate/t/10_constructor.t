use strict;
use warnings;
use Test::Exception tests => 3;
use Plack::Builder;

# no formats specified
throws_ok { builder { enable 'Negotiate' } } 
	qr/requires formats/, 'constructor requires formats';

throws_ok { builder { enable 'Negotiate', formats => { } } } 
	qr/requires formats/, 'constructor requires formats';

throws_ok { builder { enable 'Negotiate', 
		formats => { foo => { } } 
	} } qr/requires type/, 'formats must have a type';
