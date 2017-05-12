use strict;
use warnings FATAL   => 'all';
use Test::More tests => 13;
use constant EPS     => 1e-3;
use Statistics::Data;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();
isa_ok( $dat, 'Statistics::Data' );

my $cmp_aref = Array::Compare->new;

my ( $count, @data1, @data2 ) = ();

@data1 = ( 1, 2, 3, 3, 3, 1, 4, 2, 1, 2 );    # 10 elements
@data2 = ( 2, 4, 4, 1, 3, 3, 5, 2, 3, 5 );
my $aref;

eval { $dat->load( dist1 => \@data1 ); };
ok( !$@, $@ );
eval { $aref = $dat->get_aref( name => 'dist1' ) };
ok( !$@, $@ );
$count = scalar @{$aref};
ok( $count == 10, "Error in get_aref(): $count (got) != 10 (sought)" );


eval { $dat->add( dist2 => \@data2 ); };
ok( !$@, $@ );

# get everything:
eval { $aref = $dat->get_aref() };
ok( $@, $@ );

eval { $aref = $dat->get_aref( name => 'dist1' ) };
ok( !$@, $@ );
$count = scalar @{$aref};
ok( $count == 10, "Error in get_aref(): $count (got) != 10 (sought)" );

ok(
    $cmp_aref->simple_compare( \@data1, $aref ),
    'Error in get_aref(): got ' . join( '', @$aref )
);

eval { $aref = $dat->get_aref( name => 'dist2' ) };
ok( !$@, $@ );
$count = scalar @{$aref};
ok( $count == 10, "Error in get_aref(): $count (got) != 10 (sought)" );

ok(
    $cmp_aref->simple_compare( \@data2, $aref ),
    'Error in get_aref(): got ' . join( '', @$aref )
);

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
