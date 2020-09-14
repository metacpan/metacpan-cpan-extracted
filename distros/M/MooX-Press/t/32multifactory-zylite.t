use strict;
use warnings;
use Test::More;

use Types::Standard qw( Str StrMatch );

use Zydeco::Lite;

app 'Local::MyApp', sub {
	class 'Person' => sub {
		has 'name!' => ();
		factory();
		
		class 'Man' => sub {
			multi_factory 'new_person' => [ Str, StrMatch[qr/^m/i] ] => sub {
				my ( $factory, $class, $name, $gender ) = ( shift, shift, @_ );
				return $class->new( name => $name );
			};
		};
		
		class 'Woman' => sub {
			multi_factory 'new_person' => [ Str, StrMatch[qr/^f/i] ] => sub {
				my ( $factory, $class, $name, $gender ) = ( shift, shift, @_ );
				return $class->new( name => $name );
			};
		};
	};
};

# diag explain [ 'Sub::MultiMethod'->get_multimethod_candidates('Local::MyApp', 'new_person') ];

my $alice = 'Local::MyApp'->new_person( 'Alice',  'female' );
my $bob   = 'Local::MyApp'->new_person( 'Robert', 'male'   );

isa_ok( $alice, 'Local::MyApp::Types'->get_type('Woman')->class );
isa_ok( $bob,   'Local::MyApp::Types'->get_type('Man')->class );

done_testing;
