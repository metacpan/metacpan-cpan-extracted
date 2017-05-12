# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 6;

BEGIN { 
	use_ok( 'Games::Roguelike::World' ); 
	use_ok( 'Games::Roguelike::Area' ); 
	use_ok( 'Games::Roguelike::Console' ); 
}

my $w = Games::Roguelike::World->new(noconsole=>1);
isa_ok ($w, 'Games::Roguelike::World');

my $a = Games::Roguelike::Area->new();
isa_ok ($a, 'Games::Roguelike::Area');

my $c = Games::Roguelike::Console->new(noinit=>1);
isa_ok ($c, 'Games::Roguelike::Console');
