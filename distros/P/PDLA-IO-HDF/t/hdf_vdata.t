#!/usr/bin/perl -w
#
# t/hdf_vdata.t
#
# Tests Vdata features of the HDF library.
#
# 29 March 2006
# Judd Taylor, USF IMaRS
#
use strict;
use PDLA;
use PDLA::IO::HDF;
use PDLA::IO::HDF::VS;
use Test::More tests => 21;
use File::Temp qw(tempdir);

sub tapprox
{
    my $a = shift;
    my $b = shift;
    my $d = abs($a - $b);
    #ok( all($d < 1.0e-5) );
    return all($d < 1.0e-5);
}

# Vdata test suite
my $tmpdir = tempdir( CLEANUP => 1 );

my $testfile = "$tmpdir/vdata.hdf";

# creating

# TEST 1:
my $Hid = PDLA::IO::HDF::VS::_Hopen( $testfile, PDLA::IO::HDF->DFACC_CREATE, 2);
ok( $Hid != PDLA::IO::HDF->FAIL );

PDLA::IO::HDF::VS::_Vstart( $Hid );
my $vdata_id = PDLA::IO::HDF::VS::_VSattach( $Hid, -1, "w" );
PDLA::IO::HDF::VS::_VSsetname( $vdata_id, 'vdata_name' );
PDLA::IO::HDF::VS::_VSsetclass( $vdata_id, 'vdata_class' );

# TEST 2:
my $vdata_ref = PDLA::IO::HDF::VS::_VSgetid( $Hid, -1 );
ok( $vdata_ref != PDLA::IO::HDF->FAIL );

# TEST 3:
my $name = "";
PDLA::IO::HDF::VS::_VSgetname( $vdata_id, $name );
ok( $name eq "vdata_name" );

# TEST 4:
my $class = "";
PDLA::IO::HDF::VS::_VSgetclass( $vdata_id, $class );
ok( $class eq "vdata_class" );

my $data = PDLA::float sequence(10);
my $HDFtype = $PDLA::IO::HDF::SDtypeTMAP->{$data->get_datatype()};

# TEST 5:
ok( PDLA::IO::HDF::VS::_VSfdefine( $vdata_id, 'PX', $HDFtype, 1) );

# TEST 6:
ok( PDLA::IO::HDF::VS::_VSsetfields( $vdata_id, 'PX') );

# TEST 7:
ok( PDLA::IO::HDF::VS::_VSwrite( $vdata_id, $data, 10, PDLA::IO::HDF->FULL_INTERLACE ) );

PDLA::IO::HDF::VS::_VSdetach( $vdata_id );
PDLA::IO::HDF::VS::_Vend( $Hid );

# TEST 8:
ok( PDLA::IO::HDF::VS::_Hclose( $Hid ) );

# TEST 9:
undef( $Hid );
$Hid = PDLA::IO::HDF::VS::_Hopen( $testfile, PDLA::IO::HDF->DFACC_READ, 2 );
ok( $Hid != PDLA::IO::HDF->FAIL );

PDLA::IO::HDF::VS::_Vstart( $Hid );

# TEST 10:
$vdata_ref = PDLA::IO::HDF::VS::_VSfind( $Hid, 'vdata_name' );
ok( $vdata_ref != PDLA::IO::HDF->FAIL );

# TEST 11:
$vdata_id = PDLA::IO::HDF::VS::_VSattach( $Hid, $vdata_ref, "r" );
ok( $vdata_id != PDLA::IO::HDF->FAIL );

# TEST 12:
my $vdata_size = 0;
my $n_records = 0;
my $interlace = 0;
my $fields = "";
my $vdata_name = "";
ok( PDLA::IO::HDF::VS::_VSinquire( $vdata_id, $n_records, $interlace, $fields, $vdata_size, $vdata_name) );

# TEST 13:
my @tfields = split(",",$fields);
my $data_type = PDLA::IO::HDF::VS::_VFfieldtype( $vdata_id, 0 );
$data = ones( $PDLA::IO::HDF::SDinvtypeTMAP2->{$data_type}, 10 );
ok( PDLA::IO::HDF::VS::_VSread( $vdata_id, $data, $n_records, $interlace ) );

# TEST 14:
my $expected_data = sequence(10);
ok( sub { tapprox( $data, $expected_data ) } );

PDLA::IO::HDF::VS::_VSdetach( $vdata_id );
PDLA::IO::HDF::VS::_Vend( $Hid );

# TEST 15:
ok( PDLA::IO::HDF::VS::_Hclose( $Hid ) );

# TEST 16:
my $vdataOBJ = PDLA::IO::HDF::VS->new( $testfile );
ok( defined( $vdataOBJ ) );

# TEST 17:
my @vnames = $vdataOBJ->VSgetnames();
ok( scalar( @vnames ) > 0 );

foreach my $name ( @vnames ) 
{
    # TEST 18:
    my @fields = $vdataOBJ->VSgetfieldnames( $name );
    ok( scalar( @fields ) > 0 );    
    
    foreach my $field ( @fields ) 
    {
        # TEST 19:
        my $data = $vdataOBJ->VSread( $name, $field );
        ok( defined( $data ) );
    }
}

# TEST 20:
ok( $vdataOBJ->close() );
undef( $vdataOBJ );

# TEST 21:
$vdataOBJ=PDLA::IO::HDF::VS->new( $testfile );
foreach my $name ( $vdataOBJ->VSgetnames() ) 
{ 
    print "name: $name\n";
    foreach my $field ( $vdataOBJ->VSgetfieldsnames( $name ) ) 
    {
        print "   $field\n";
        my $data = $vdataOBJ->VSread( $name, $field );
        print "     " . $data->info() . "\n";
        print "        $data\n";
    }
}
ok( 1 );

# Remove the testfile:
unlink( $testfile );

exit(0);

