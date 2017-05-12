use strict;
use warnings FATAL   => 'all';
use Test::More tests => 39;
use constant EPS     => 1e-3;
use Statistics::Data;
use Array::Compare;

BEGIN {
    use_ok('Statistics::Data') || print "Bail out!\n";
}

my $dat = Statistics::Data->new();
isa_ok( $dat, 'Statistics::Data' );

my $cmp_aref = Array::Compare->new;

my ( $ret_data, @data1, @data2, @data1e ) = ();

@data1 = ( 1, 2, 3, 3, 3, 1, 4, 2, 1, 2 );    # 10 elements
@data2 = ( 2, 4, 4, 1, 3, 3, 5, 2, 3, 5 );
@data1e = ( @data1, 'a', 'b' );

# TEST load/add/get_aref for each case: case numbers are those in the POD for load() method:

# CASE 1
eval { $dat->load(@data1); };
ok( !$@, "Error in load of Case 1 (unreferenced unnamed array): $@" );

# should be stored as aref named 'aref' in the first index of _DATA:
ok( ref $dat->{_DATA}->[0]->{'aref'} eq 'ARRAY',
    "Error in load() of Case 1 (unreferenced unnamed array): not an aref" );
$ret_data = $dat->get_aref();
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref() after Case 1 load(): got ' . join( '', @$ret_data ) );
eval { $dat->add( 'a', 'b' ); };
ok( !$@, "Error in add: Case 1" );
$ret_data = $dat->get_aref();
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref() after Case 1 add(): got ' . join( '', @$ret_data ) );

# CASE 2
eval { $dat->load( \@data1 ); };
ok( !$@, "Error in load: Case 2" );
$ret_data = $dat->get_aref();
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref() after Case 2 load(): got ' . join( '', @$ret_data ) );
eval { $dat->add( [ 'a', 'b' ] ); };
ok( !$@, "Error in add: Case 2" );
$ret_data = $dat->get_aref();
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref() after Case 2 add(): got ' . join( '', @$ret_data ) );

# CASE 3
eval { $dat->load( data => \@data1 ); };
ok( !$@, "Error in load: Case 3" );

# should be stored as aref named 'aref' in the first index of _DATA:
ok(
    ref $dat->{_DATA}->[0]->{'aref'} eq 'ARRAY',
"Error in load() of Case 3 (named data as hash of arefs): not an aref"
);
ok(
    $dat->{_DATA}->[0]->{'name'} eq 'data',
"Error in load() of Case 3 (named data as hash of arefs): not correctly named as 'data'"
);
$ret_data = $dat->get_aref( name => 'data' );
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref after load: Case 3: got ' . join( '', @$ret_data ) );
eval { $dat->add( data => [ 'a', 'b' ] ); };
ok( !$@, "Error in add: Case 3" );
$ret_data = $dat->get_aref( name => 'data' );
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref after add: Case 3: got ' . join( '', @$ret_data ) );

# CASE 4
eval { $dat->load( { vascular => \@data1 } ); };
ok( !$@, "Error in load: Case 4" );
$ret_data = $dat->get_aref( name => 'vascular' );
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref after load: Case 4: got ' . join( '', @$ret_data ) );
eval { $dat->add( { vascular => [ 'a', 'b' ] } ); };
ok( !$@, "Error in add: Case 4" );
$ret_data = $dat->get_aref( name => 'vascular' );
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref after add: Case 4: got ' . join( '', @$ret_data ) );

# CASE 5
eval { $dat->load( dist1 => \@data1, dist2 => \@data2 ); };
ok( !$@, "Error in load: Case 5" );
my $num = $dat->ndata();
ok(
    $num == 2,
    "Error in load of multiple data by hash: Should be two arrays, got $num"
);
$ret_data = $dat->get_aref( name => 'dist1' );
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref after load: Case 5: got ' . join( '', @$ret_data ) );
eval { $dat->add( dist1 => [ 'a', 'b' ] ); };
ok( !$@, "Error in add: Case 5" );
$ret_data = $dat->get_aref( name => 'dist1' );
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref after add: Case 5: got ' . join( '', @$ret_data ) );

# CASE 6:
eval { $dat->load( { dist1 => \@data1, dist2 => \@data2 } ); };
ok( !$@ );
$num = $dat->ndata();
ok(
    $num == 2,
"Error in load of multiple data by hashref: Should be two arrays, got $num"
);
$ret_data = $dat->get_aref( name => 'dist1' );
ok( $cmp_aref->simple_compare( \@data1, $ret_data ),
    'Error in get_aref after load: Case 6: got ' . join( '', @$ret_data ) );
eval { $dat->add( dist1 => [ 'a', 'b' ] ); };
ok( !$@, "Error in add: Case 6" );
$ret_data = $dat->get_aref( name => 'dist1' );
ok( $cmp_aref->simple_compare( \@data1e, $ret_data ),
    'Error in get_aref after add: Case 6: got ' . join( '', @$ret_data ) );

# check can get_aref() all named data:
#my %alldata = $dat->get_aref();
#$num = scalar(keys %alldata);
#ok($num == 2, "Error in get_aref of multiple data as hash: Should be two arrays, got $num");
#ok(exists($alldata{'dist1'}), "Error in get_aref of multiple data as hash: 'dist1' is not returned");
#ok(exists($alldata{'dist2'}), "Error in get_aref of multiple data as hash: 'dist2' is not returned");

# unload() test:
eval { $dat->unload(); };
ok( !$@,                        "Error in unload" );
ok( !scalar @{ $dat->{_DATA} }, 'Error in total unload' );
ok( $dat->ndata() == 0,
    "Error in unload - Number of loaded arrays does not equal 0" );

# - named unload()
$dat->load( { dist1 => \@data1, dist2 => \@data2 } );
eval { $dat->unload( name => 'dist1' ); };
ok( !$@, "Error in unload" );
ok( $dat->ndata() == 1,
    "Number of loaded arrays does not equal 1 after unload()" );
$dat->add( 'dist1' => ['3'] );    # should be nothing in there but 3 now
ok( $dat->ndata() == 2,
    "Number of loaded arrays does not equal 2 after add()" );
$ret_data = $dat->get_aref( name => 'dist1' );
ok( $cmp_aref->simple_compare( [3], $ret_data ),
    'Error in get_aref after unload and add: got ' . join( '', @$ret_data ) );

# - but dist2 should be still okay:
$ret_data = $dat->get_aref( name => 'dist2' );
ok( $cmp_aref->simple_compare( \@data2, $ret_data ),
    'Error in get_aref after unload and add: got ' . join( '', @$ret_data ) );

# multiple get_aref()
#$dat->load({dist1 => \@data1, dist2 => \@data2});
#my ($d1, $d2) = $dat->get_aref(labels => [qw/dist1 dist2/]);
#ok( $cmp_aref->simple_compare(\@data1, $d1), 'Error in multiple get_aref');
#ok( $cmp_aref->simple_compare(\@data2, $d2), 'Error in multiple get_aref');
#my $dref = $dat->get_aref(labels => [qw/dist1 dist2/]);
#ok( $cmp_aref->simple_compare(\@data1, $dref->[0]), 'Error in multiple get_aref');
#ok( $cmp_aref->simple_compare(\@data2, $dref->[1]), 'Error in multiple get_aref');

#my $clone = $dat->clone();
#$dref = $clone->get_aref(labels => [qw/dist1 dist2/]);
#ok( $cmp_aref->simple_compare(\@data1, $dref->[0]), 'Error in multiple get_aref after clone');

sub equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
