use strict;
use warnings;
use Test::More;

use MooX::Press (
	prefix => 'MyApp',
	role => [
		'Foo' => {
			can => {
				'bar' => sub { 42 },
			},
		},
	],
	with => 'Foo',
	around => [
		'bar' => sub {
			my ( $next, $self ) = ( shift, shift, @_ );
			2 * $self->$next(@_);
		},
	],
);

ok( MyApp->DOES('MyApp::Foo') );

is( MyApp->bar, 84 );

done_testing;
