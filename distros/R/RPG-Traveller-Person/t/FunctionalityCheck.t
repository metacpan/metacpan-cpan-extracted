use Test::More;
use_ok("RPG::Traveller::Person");

my $p;

{
    $p = RPG::Traveller::Person->new();
    ok( $p, "Instantiation of module" );
}

{
    $p->initUPP;
    ok(1);
}

{
    ok( $p->strength() > 0, "Strength initialized" );
}

{
    ok( $p->strength() > 0, "Strength initialized" );
}

{
    ok( $p->dexterity() > 0, "Dexterity initialized" );
}

{
    ok( $p->endurance() > 0, "Endurance initialized" );
}

{
    ok( $p->intelligence() > 0, "Intelligenc initialized" );
}

{
    ok( $p->education() > 0, "Education initialized" );
}

{
    ok( $p->social_standing() > 0, "Social Standing initialized" );
}

{
    ok( $p->age() == 18, "Age initialized" );
}
{
    my $string = $p->upp2string();
    ok( $string, "upp2string test" );
    diag($string);
}

{
    my $string = $p->toString();
    ok( $string, "toString test" );
    diag($string);
}

done_testing;
