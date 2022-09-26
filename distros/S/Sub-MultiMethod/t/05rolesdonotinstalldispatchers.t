use 5.008;
use strict;
use warnings;
use Test::More;

package Game::Paper     ; use Class::Tiny;
package Game::Scissors  ; use Class::Tiny;
package Game::Rock      ; use Class::Tiny;
package Game::Lizard    ; use Class::Tiny;
package Game::Spock     ; use Class::Tiny;

BEGIN {
	package Game::Types;
	use Type::Library -base;
	use Types::Standard qw(Any InstanceOf);
	__PACKAGE__->add_type(
		name   => 'Any',
		parent => Any,
	);
	__PACKAGE__->add_type(
		name   => $_,
		parent => InstanceOf["Game::$_"],
	) for qw( Paper Scissors Rock Lizard Spock );
	$INC{'Game/Types.pm'} = 1;
}

package Game::Combos::Base; {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod qw(multimethod);
	
	multimethod play => (
		positional => [Any, Any],
		code       => sub { 0 },
	);
	
	no Sub::MultiMethod;
}

package Game::Combos::Standard; {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod qw( multimethod );
	
	with qw( Game::Combos::Base );
	
	multimethod play => (
		positional => [Paper, Rock],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Scissors, Paper],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Rock, Scissors],
		code       => sub { 1 },
	);

	no Sub::MultiMethod;
}

package Game::Combos::Extra; {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod qw( multimethod );
	
	with qw( Game::Combos::Standard );

	multimethod play => (
		positional => [Paper, Spock],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Scissors, Lizard],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Rock, Lizard],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Lizard, Paper],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Lizard, Spock],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Spock, Rock],
		code       => sub { 1 },
	);
	multimethod play => (
		positional => [Spock, Scissors],
		code       => sub { 1 },
	);

	no Sub::MultiMethod;
}

package Game::Standard; {
	use Class::Tiny;
	use Role::Tiny::With;

	with qw( Game::Combos::Standard );
}

package Game::Extended; {
	use Class::Tiny;
	use Role::Tiny::With;

	with qw( Game::Combos::Extra );
}

package main;

my $game = Game::Extended->new;
is( $game->play(Game::Paper->new, Game::Rock->new),      1 );
is( $game->play(Game::Spock->new, Game::Paper->new),     0 );
is( $game->play(Game::Spock->new, Game::Scissors->new),  1 );

done_testing;
