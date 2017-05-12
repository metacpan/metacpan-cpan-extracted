use Test::More;
use RPG::Traveller::Person::Constants qw/:all/;

{
    ok( int2skill(PILOT) eq "Pilot", "SKill constants test" );
}
{
    ok( int2career(MARINE) eq "Marine", "Career constants test" );
}

done_testing;
