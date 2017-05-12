#!perl -Tw

use strict;
use utf8;

use Test::More tests => 5;
use lib "./lib";
use SeeAlso::Identifier::ISIL qw(sigel2isil);

my $isil = SeeAlso::Identifier::ISIL->new("DE-7");
ok ( $isil->valid , "simple ISIL" );

$isil->value(" ISIL DE-7 ");
ok ( $isil->valid , "spaces and 'ISIL' before ISIL" );
ok ( $isil->normalized eq 'info:isil/DE-7' , "normalized ISIL as URI" );

$isil = sigel2isil("Gö 116");
ok ( $isil->value eq "DE-Goe116" , "sigel2isil" );

is ($isil->indexed, "DE-GOE116", "indexed version (uppercase)");