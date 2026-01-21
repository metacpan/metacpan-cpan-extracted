package Container;

use Moo;
use MooX::XSConstructor;

use MyTest;

has 'test' => (
	is => 'ro',
	default => sub {
		my ( $self ) = @_;
		MyTest->new( x => $self );
	},
);

1;
