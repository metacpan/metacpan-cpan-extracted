use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

my @modules = qw(
    Physics::Etch
    Physics::Etch::Material
    Physics::Etch::Etchant
    Physics::Etch::Process
    Physics::Etch::WetEtch
    Physics::Etch::DryEtch
);

use_ok($_) for @modules;

# Material
my $m = Physics::Etch::Material->new(
    name => 'copper', formula => 'Cu', pretty => 'Copper', thickness => 500 );
is( $m->label,     'Copper (Cu)', 'material label' );
is( $m->thickness, 500,           'material thickness' );
$m->thickness(300);
is( $m->thickness, 300, 'material thickness is mutable' );

# Etchant
my $e = Physics::Etch::Etchant->new( name => 'FeCl3', type => 'wet' );
ok( $e->is_wet && !$e->is_dry, 'etchant wet/dry flags' );
eval { Physics::Etch::Etchant->new( name => 'x', type => 'plasma' ) };
like( $@, qr/wet.*dry/, 'invalid etchant type rejected' );

# required-arg validation
eval { Physics::Etch::Material->new() };
like( $@, qr/name/, 'material requires name' );

done_testing;
