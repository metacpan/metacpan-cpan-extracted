use Test::More tests => 4;
use UNIVERSAL;
use RPG::Traveller::Starmap::Subsector;
{
    ok( RPG::Traveller::Starmap::Subsector->can(name), "Name Test" )
}
{
    ok( RPG::Traveller::Starmap::Subsector->can(density), "Density Test" )
}
{
    ok( RPG::Traveller::Starmap::Subsector->can(posit), "Pos Test" )
}
{
    ok( RPG::Traveller::Starmap::Subsector->can(generate), "Generate Test" )
}
