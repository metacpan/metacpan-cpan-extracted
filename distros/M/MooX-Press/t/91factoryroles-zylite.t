use strict;
use warnings;
use Test::More;

use Zydeco::Lite;

app 'MyApp' => sub {
	
	with 'Foo';
	
	around 'bar' => sub {
		my ( $next, $self ) = ( shift, shift, @_ );
		2 * $self->$next(@_);
	};
	
	role 'Foo' => sub {
		method 'bar' => sub { 42 };
	};
};

ok( MyApp->DOES('MyApp::Foo') );

is( MyApp->bar, 84 );

done_testing;
