use v5.24;
use warnings;

package Game {
	use Zydeco;
	
	class Paper        { factory paper    }
	class Scissors     { factory scissors }
	class Rock         { factory rock     }
	class Lizard       { factory lizard   }
	class Spock        { factory spock    }
	
	class Standard {
		with Combos::Standard;
	}
	
	role Combos::Standard {
		with Combos::Base;
		multi method play (Paper    $x, Rock     $y) { 1 }
		multi method play (Scissors $x, Paper    $y) { 1 }
		multi method play (Rock     $x, Scissors $y) { 1 }
	}
	
	role Combos::Base {
		multi method play (Any      $x, Any      $y) { 0 }
	}
	
	class Extended {
		with Combos::Extra;
	}
	
	role Combos::Extra {
		with Combos::Standard;
		multi method play (Paper    $x, Spock    $y) { 1 }
		multi method play (Scissors $x, Lizard   $y) { 1 }
		multi method play (Rock     $x, Lizard   $y) { 1 }
		multi method play (Lizard   $x, Paper    $y) { 1 }
		multi method play (Lizard   $x, Spock    $y) { 1 }
		multi method play (Spock    $x, Rock     $y) { 1 }
		multi method play (Spock    $x, Scissors $y) { 1 }
	}
}

my $game = Game->new_extended;
say $game->play(Game->paper, Game->rock);       # 1, Paper covers Rock
say $game->play(Game->spock, Game->paper);      # 0, Paper disproves Spock
say $game->play(Game->spock, Game->scissors);   # 1, Spock smashes Scissors

