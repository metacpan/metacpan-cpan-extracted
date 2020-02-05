use v5.12;
use strict;
use warnings;

package Game::Paper     { use Class::Tiny; }
package Game::Scissors  { use Class::Tiny; }
package Game::Rock      { use Class::Tiny; }
package Game::Lizard    { use Class::Tiny; }
package Game::Spock     { use Class::Tiny; }

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

package Game::Combos::Base {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod -role, qw(multimethod);
	
	multimethod play => (
		signature => [Any, Any],
		code      => sub { 0 },
	);
	
	no Sub::MultiMethod;
}

package Game::Combos::Standard {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod -role, qw( multimethod multimethods_from_roles );
	
	with qw( Game::Combos::Base );
	multimethods_from_roles qw( Game::Combos::Base );
	
	multimethod play => (
		signature => [Paper, Rock],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Scissors, Paper],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Rock, Scissors],
		code      => sub { 1 },
	);

	no Sub::MultiMethod;
}

package Game::Combos::Extra {
	use Role::Tiny;
	use Game::Types -types;
	use Sub::MultiMethod -role, qw( multimethod multimethods_from_roles );
	
	with qw( Game::Combos::Standard );
	multimethods_from_roles qw( Game::Combos::Standard );

	multimethod play => (
		signature => [Paper, Spock],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Scissors, Lizard],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Rock, Lizard],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Lizard, Paper],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Lizard, Spock],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Spock, Rock],
		code      => sub { 1 },
	);
	multimethod play => (
		signature => [Spock, Scissors],
		code      => sub { 1 },
	);

	no Sub::MultiMethod;
}

package Game::Standard {
	use Class::Tiny;
	use Role::Tiny::With;
	use Sub::MultiMethod qw( multimethods_from_roles );

	with qw( Game::Combos::Standard );
	multimethods_from_roles qw( Game::Combos::Standard );
}

package Game::Extended {
	use Class::Tiny;
	use Role::Tiny::With;
	use Sub::MultiMethod qw( multimethods_from_roles );

	with qw( Game::Combos::Extra );
	multimethods_from_roles qw( Game::Combos::Extra );
}

my $game = Game::Extended->new;
say $game->play(Game::Paper->new, Game::Rock->new);     # 1, Paper covers Rock
say $game->play(Game::Spock->new, Game::Paper->new);    # 0, Paper disproves Spock
say $game->play(Game::Spock->new, Game::Scissors->new); # 1, Spock smashes Scissors
