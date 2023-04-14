use strict;
use warnings;
use Test::More;

{
	package Local::Dummy;
	use Test::Requires 'Moo';
	use Test::Requires 'MooX::ProtectedAttributes';
	use Test::Requires 'MooX::Should';
	use Test::Requires 'Types::Standard';
};

{
	package Local::TestClass;
	use Moo;
	use MooX::Should;
	use Sub::HandlesVia;
	use MooX::ProtectedAttributes;
	use Types::Standard 'Bool';
	protected_has _client_halted => (
		is            => 'rw',
		should        => Bool,
		reader        => '_has_client_halted',
		default       => 0,
		handles_via   => 'Bool',
		handles       => {
			_halt_client => 'set',
		},
	);
}

my $client = Local::TestClass->new();
$client->_halt_client();
ok( $client->{_client_halted} );

done_testing;
