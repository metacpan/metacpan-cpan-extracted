use strict;
use warnings;
use Test::More;

use MooX::Pression prefix => 'MyApp';

class Foo {
	has name ( required => true );
	
	method bleh {
		try {}
		catch {}
		try {}
		catch {}
		if (1) {}
	}
}

try {
	MyApp->new_foo;
}
catch {
	my $e = $@;
	like($e, qr/required arguments/);
}

done_testing;
