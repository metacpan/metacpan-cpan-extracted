use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch;

# --- Database introspection ------------------------------------------------
my @mats = Physics::Etch->material_names;
for my $need (
    qw( copper photoresist aluminum_silicide tantalum titanium
    silicon_nitride polyimide )
    )
{
    ok( ( grep { $_ eq $need } @mats ), "material '$need' in database" );
}

# every requested material has at least one recipe
for my $need (
    qw( copper photoresist aluminum_silicide tantalum titanium
    silicon_nitride polyimide )
    )
{
    ok( scalar( Physics::Etch->recipes( material => $need ) ),
        "recipe exists for '$need'" );
}

# --- Factories build the right classes -------------------------------------
my $wet = Physics::Etch->wet_etch( 'copper', thickness => 500 );
isa_ok( $wet, 'Physics::Etch::WetEtch', 'wet_etch' );
is( $wet->target->formula, 'Cu', 'target material resolved from DB' );
is( $wet->thickness, 500, 'thickness override applied' );

my $dry = Physics::Etch->dry_etch( 'silicon_nitride', thickness => 200 );
isa_ok( $dry, 'Physics::Etch::DryEtch', 'dry_etch' );

# --- Overrides win over recipe defaults ------------------------------------
my $ov = Physics::Etch->wet_etch( 'copper', thickness => 500, rate => 1234 );
is( $ov->rate, 1234, 'user rate override wins' );

my $temp = Physics::Etch->wet_etch( 'copper', thickness => 500, temperature => 60 );
ok( $temp->vertical_rate > $wet->vertical_rate, 'temperature override speeds etch' );

# --- Etchant selection -----------------------------------------------------
my $aps = Physics::Etch->wet_etch( 'copper', etchant => 'APS', thickness => 500 );
is( $aps->etchant->name, 'APS', 'specific etchant selected' );

# --- Mask / substrate defaults from recipe ---------------------------------
ok( $wet->mask,      'default mask attached from recipe' );
ok( $wet->substrate, 'default substrate attached from recipe' );

# --- Unknown material fails cleanly ----------------------------------------
eval { Physics::Etch->wet_etch('unobtainium') };
like( $@, qr/no wet recipe|unknown material/i, 'unknown material errors' );

# --- report() runs for both process types ----------------------------------
like( $wet->report, qr/WET ETCH/, 'wet report renders' );
like( $dry->report, qr/DRY ETCH/, 'dry report renders' );

done_testing;
