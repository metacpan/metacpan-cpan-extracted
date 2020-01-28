use strict;
use warnings;
use Test::More;

use MooX::Pression prefix => 'MyApp';

class Foo {
	has name ( required => true );
}

try {
	MyApp->new_foo;
}
catch {
	my $e = $@;
	like($e, qr/required arguments/);
}

done_testing;
