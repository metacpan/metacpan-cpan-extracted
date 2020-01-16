use v5.14;
use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	
	class Animal {
		has name;
		class Mammal {
			class Dog;
			class Cat {
				with Cute?;
			}
			class Primate {
				class Monkey;
				class Gorilla;
				class ::Human {
					has +name ( required => 1 );
					class Superhuman;
				}
			}
		}
		class Fish;
		class Bird {
			has wings;
			class Penguin {
				with Flightless?;
			}
			class Corvid {
				with Evil?;
				class Crow;
				class Magpie;
			}
		}
		class Reptile;
		class Amphibian {
			class Frog;
			class Toad;
		}
		class Invertebrate;
	}
}

my $superman = MyApp->new_superhuman(name => 'Kal El');

isa_ok($superman, $_) for qw(
	MyApp::Animal
	MyApp::Mammal
	MyApp::Primate
	Human
	MyApp::Superhuman
);

done_testing;
