use strict;
use warnings FATAL   => 'all';
use Test::More tests => 21;
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
my $hoa;

# get everything:
eval { $hoa = $dat->get_hoa() };
ok( !$@, $@ );
$count = scalar keys %{$hoa};
ok( $count == 2, "Error in get_hoa(): $count (got) != 2 (sought)" );

eval { $hoa = $dat->get_hoa( name => 'dist1' ) };
ok( !$@, $@ );
$count = scalar @{ $hoa->{'dist1'} };
ok( $count == 10, "Error in get_hoa(): $count (got) != 10 (sought)" );

eval { $hoa = $dat->get_hoa( name => ['dist1'] ) };
ok( !$@, $@ );
$count = scalar @{ $hoa->{'dist1'} };
ok( $count == 10, "Error in get_hoa(): $count (got) != 10 (sought)" );

# no valid lab throws up no ref?
eval { $hoa = $dat->get_hoa( name => 'wobble' ) };
ok( !$@, $@ );
my $refstr = ref $hoa->{'wobble'};
ok( !length($refstr),
    "Error in get_hoa(): got a ref-type; sought no length" );

# want a list:
my %hoa = ();
eval { %hoa = $dat->get_hoa( name => 'wobble' ) };
ok( !$@, 'get_hoa should be able to return a list' );

eval { $dat->load( dist1 => [ 1, '', 3 ], dist2 => [ 2, 3, '', 'a' ] ); };
ok( !$@, $@ );

my $hoa_clean = $dat->get_hoa_numonly_indep( label => [qw/dist1 dist2/] );
ok(
    scalar( @{ $hoa_clean->{'dist1'} } ) == 2,
    "Purge of non-numeric within list failed"
);
ok(
    scalar( @{ $hoa_clean->{'dist2'} } ) == 2,
    "Purge of non-numeric within list failed"
);

$hoa_clean = $dat->get_hoa_numonly_across( name => [qw/dist1 dist2/] );
ok(
    scalar( @{ $hoa_clean->{'dist1'} } ) == 1,
    "Purge of non-numeric within list failed"
);
ok(
    scalar( @{ $hoa_clean->{'dist2'} } ) == 1,
    "Purge of non-numeric within list failed"
);

eval {
    $dat->load(
        dist1 => [ 1,  q{}, 3,   4,    5 ],
        dist2 => [ 2,  3,   q{}, q{a}, 5 ],
        dist3 => [ 11, 12,  13,  14,   15, q{} ]
    );
};

$hoa_clean =
  $dat->get_hoa_numonly_across( name => [qw/dist1 dist2 dist3/] );

# Arrays should be of equal size:
ok(
    scalar( @{ $hoa_clean->{'dist1'} } ) == 2,
    "Purge of non-numeric within list failed"
);
ok(
    scalar( @{ $hoa_clean->{'dist2'} } ) == 2,
    "Purge of non-numeric within list failed"
);
ok(
    scalar( @{ $hoa_clean->{'dist3'} } ) == 2,
    "Purge of non-numeric within list failed"
);
ok(
    $dat->{'purged'} == 4,
    'argument \'purged\' is not correct in get_hoa method = ' . $dat->{'purged'}
);

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
