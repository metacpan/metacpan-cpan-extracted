# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 22;

BEGIN { use_ok( 'String::ProperCase::Surname' ); }

is(ProperCase("Normal"), "Normal", "Normal Case passthrough");
is(ProperCase("lower"), "Lower", "lower Case fix");
is(ProperCase("UPPER"), "Upper", "UPPER Case fix");
is(ProperCase("o'brien"), "O'Brien", "O' Cases");
is(ProperCase("O'NEAL"), "O'Neal", "O' Cases");
is(ProperCase("mclean"), "McLean", "Mc Cases");
is(ProperCase("MCCLUE"), "McClue", "Mc Cases");
is(ProperCase("Hyphen-Nated"), "Hyphen-Nated", "Hyphen-Nated");
is(ProperCase("HYPHEN-NATED"), "Hyphen-Nated", "Hyphen-Nated");
is(ProperCase("hyphen-nated"), "Hyphen-Nated", "Hyphen-Nated");
is(ProperCase("mclean-mcclue"), "McLean-McClue", "Hyphenated Mc-Mc");
is(ProperCase("mclean-o'brien"), "McLean-O'Brien", "Hyphenated Mc-O");
is(ProperCase("MacDonald"), "MacDonald", "Mac");
is(ProperCase("macdonald"), "MacDonald", "Mac");
is(ProperCase("MACDONALD"), "MacDonald", "Mac");
is(ProperCase("DeVaux-DeVoir"), "DeVaux-DeVoir", "De");
is(ProperCase("DEVAUX-DEVOIR"), "DeVaux-DeVoir", "De");
is(ProperCase("devaux-devoir"), "DeVaux-DeVoir", "De");

is(ProperCase("  whitespace preserved  "), "  Whitespace Preserved  ", "Whitespace Preserved");
is(ProperCase("  whitespace\tpreserved\n  \n"), "  Whitespace\tPreserved\n  \n", "Whitespace Preserved");

#This is a pet peeve of mine.
$_="Foo";
ProperCase("Normal");
is($_, "Foo", 'Preserves $_');
