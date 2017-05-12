use strict;
use warnings FATAL   => 'all';
use Test::More tests => 13;
use constant EPS     => 1e-3;
use Statistics::Data;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();
isa_ok( $dat, 'Statistics::Data' );

my ( $count, @data1, @data2 ) = ();

@data1 = ( 1, 2, 3, 3, 3, 1, 4, 2, 1, 2 );    # 10 elements
@data2 = ( 2, 4, 4, 1, 3, 3, 5, 2, 3, 5 );

eval { $dat->load( dist1 => \@data1, dist2 => \@data2 ); };
ok( !$@, $@ );
my $aoa;

# get everything:
eval { $aoa = $dat->get_aoa() };
ok( !$@, $@ );
$count = scalar @{$aoa};
ok( $count == 2, "Error in get_aoa(): $count (got) != 2 (sought)" );

eval { $aoa = $dat->get_aoa( name => 'dist1' ) };
ok( !$@, $@ );
$count = scalar @{ $aoa->[0] };
ok( $count == 10, "Error in get_aoa(): $count (got) != 10 (sought)" );

eval { $aoa = $dat->get_aoa( name => 'dist1' ) };
ok( !$@, $@ );
$count = scalar @{ $aoa->[0] };
ok( $count == 10, "Error in get_aoa(): $count (got) != 10 (sought)" );

eval { $aoa = $dat->get_aoa( name => ['dist1'] ) };
ok( !$@, $@ );
$count = scalar @{ $aoa->[0] };
ok( $count == 10, "Error in get_aoa(): $count (got) != 10 (sought)" );

# no valid name throws up no ref?
eval { $aoa = $dat->get_aoa( name => 'wobble' ) };
ok( !$@, $@ );
my $refstr = ref $aoa->[0];
ok( !length($refstr),
    "Error in get_aoa(): got a ref-type; sought no length" );

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
