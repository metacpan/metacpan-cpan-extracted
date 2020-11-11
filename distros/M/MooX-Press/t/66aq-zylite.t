use strict;
use warnings;
use Test::Requires 'Ask';
use Test::Requires 'Ask::Question';
use Test::Requires 'Ask::Callback';
use Test::More;
use Types::Standard -types;
use Zydeco::Lite;

my @inputs  = ( "Foo", 3.1, '', 3.1, 4.1, '' );
my @outputs = ();

my $Rounded = Int->plus_coercions( Num, 'int($_)' );

app 'MyLocal' => sub {
	class 'Foo' => sub {
	
		has numbers => (
			is       => 'lazy',
			isa      => ArrayRef[ $Rounded ],
			default  => Ask::Q(
				"Enter some numbers",
				backend => 'Ask::Callback'->new(
					input_callback  => sub { shift @inputs },
					output_callback => sub { push @outputs, @_ },
				),
			),
		);
	};
};


my $foo = 'MyLocal'->new_foo;

is_deeply( $foo->numbers, [ 3, 4 ] );

is_deeply( \@inputs, [] );

like $outputs[0], qr/did not pass type constraint/;

done_testing;
