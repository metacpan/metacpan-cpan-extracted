#!/usr/bin/perl

=head1 NAME

  data_matrix.t
  A piece of code to test the R::YapRI::Data::Matrix module

=cut

=head1 SYNOPSIS

 perl data_matrix.t
 prove data_matrix.t

=head1 DESCRIPTION

 Test R::YapRI::Matrix module

=cut

=head1 AUTHORS

 Aureliano Bombarely
 (aurebg@vt.edu)

=cut

use strict;
use warnings;
use autodie;

use Data::Dumper;
use Test::More;
use Test::Exception;
use Test::Warn;

use Cwd;

use FindBin;
use lib "$FindBin::Bin/../lib";

## Before run any test it will check if R is available

BEGIN {
    my $r;
    if (defined $ENV{RBASE}) {
	$r = $ENV{RBASE};
    }
    else {
	my $path = $ENV{PATH};
	if (defined $path) {
	    my @paths = split(/:/, $path);
	    foreach my $p (@paths) {
		if ($^O =~ m/MSWin32/) {
		    my $wfile = File::Spec->catfile($p, 'Rterm.exe');
		    if (-e $wfile) {
			$r = $wfile;
		    }
		}
		else {
		    my $ufile = File::Spec->catfile($p, 'R');
		    if (-e $ufile) {
			$r = $ufile;
		    }
		}
	    }
	}
    }

    ## Now it will plan or skip the test

    unless (defined $r) {
	plan skip_all => "No R path was found in PATH or RBASE. Aborting test.";
    }

    plan tests => 122;
}



## TEST 1 and 2

BEGIN {
    use_ok('R::YapRI::Data::Matrix');
    use_ok('R::YapRI::Base')
}

## Add the object created to an array to clean them at the end of the script

my @rih_objs = ();

## First, create the empty object and check it, TEST 3 to 6

my $matrix0 = R::YapRI::Data::Matrix->new();

is(ref($matrix0), 'R::YapRI::Data::Matrix', 
    "testing new() for an empty object, checking object identity")
    or diag("Looks like this has failed");

throws_ok { R::YapRI::Data::Matrix->new('fake') } qr/ARGUMENT ERROR: Arg./, 
    'TESTING DIE ERROR when arg. supplied new() function is not hash ref.';

throws_ok { R::YapRI::Data::Matrix->new({fake => 1}) } qr/ARGUMENT ERROR: fake/, 
    'TESTING DIE ERROR when arg. key supplied new() function is not permited.';

throws_ok { R::YapRI::Data::Matrix->new({data => 1}) } qr/ARGUMENT ERROR: 1/, 
    'TESTING DIE ERROR when arg. val supplied new() function is not permited.';


#######################
## TESTING ACCESSORS ##
#######################

## name accessor, TEST 7 and 8

$matrix0->set_name('test0');

is($matrix0->get_name(), 'test0', 
    "testing get/set_name, checking name identity")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_name() } qr/ERROR: No defined name/, 
    'TESTING DIE ERROR when no arg. was supplied to set_name() function';

## coln accessor, TEST 9 to 11

$matrix0->set_coln(3);

is($matrix0->get_coln(), 3, 
    "testing get/set_coln, checking column number")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_coln() } qr/ERROR: No defined coln/, 
    'TESTING DIE ERROR when no arg. was supplied to set_coln() function';

throws_ok { $matrix0->set_coln('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to set_coln() function isnt digit';


## rown accessor, TEST 12 to 14

$matrix0->set_rown(2);

is($matrix0->get_rown(), 2, 
    "testing get/set_rown, checking row number")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_rown() } qr/ERROR: No defined rown/, 
    'TESTING DIE ERROR when no arg. was supplied to set_rown() function';

throws_ok { $matrix0->set_rown('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to set_rown() function isnt digit';


## colnames accessor, TEST 15 to 18

$matrix0->set_colnames([ 1, 2, 3]);
is(join(',', @{$matrix0->get_colnames()}), '1,2,3', 
    "testing get/set_colnames, checking column names")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_colnames() } qr/ERROR: No colname_aref/, 
    'TESTING DIE ERROR when no arg. was supplied to set_colnames() function';

throws_ok { $matrix0->set_colnames('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to set_colnames() isnt ARAYREF';

throws_ok { $matrix0->set_colnames([1, 2]) } qr/ERROR: Different number/, 
    'TESTING DIE ERROR when arg. supplied to set_colnames() has diff. coln';


## rownames accessor, TEST 19 to 22

$matrix0->set_rownames([ 'A', 'B']);
is(join(',', @{$matrix0->get_rownames()}), 'A,B', 
    "testing get/set_rownames, checking row names")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_rownames() } qr/ERROR: No rowname_aref/, 
    'TESTING DIE ERROR when no arg. was supplied to set_rownames() function';

throws_ok { $matrix0->set_rownames('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to set_rownames() isnt ARAYREF';

throws_ok { $matrix0->set_rownames(['A','B','C']) } qr/ERROR: Different numb/,
    'TESTING DIE ERROR when arg. supplied to set_rownames() has diff. rown';


## data accessor, TEST 23 to 26

$matrix0->set_data([ 1, 2, 3, 4, 5, 6] );
is(join(',', @{$matrix0->get_data()}), '1,2,3,4,5,6', 
    "testing get/set_data, checking data")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_data() } qr/ERROR: No data_aref/, 
    'TESTING DIE ERROR when no arg. was supplied to set_data() function';

throws_ok { $matrix0->set_data('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to set_data() isnt ARAYREF';

throws_ok { $matrix0->set_data([1, 2, 3, 4]) } qr/ERROR: data_n = 4/,
    'TESTING DIE ERROR when arg. supplied to set_data() has diff. expected n';


########################
## INTERNAL FUNCTIONS ##
########################

## TEST 27 to 32

my %imtx = $matrix0->_index_matrix();
is(scalar(keys %imtx), $matrix0->get_rown() * $matrix0->get_coln(),
    "testing _index_matrix, checking number of indexes")
    or diag("Looks like this has failed");

$matrix0->_set_indexes(\%imtx);
is(scalar(keys %{$matrix0->_get_indexes()}), 
   $matrix0->get_rown() * $matrix0->get_coln(),
    "testing _get/set_matrix, checking number of indexes")
    or diag("Looks like this has failed");

is(join(',', sort(keys %{$matrix0->_get_rev_indexes()})), 
   join(',', sort(values %{$matrix0->_get_indexes()})),
   "testing _get_rev_indexes(), checking id of the revb indexes")
    or diag("Looks like this has failed");


throws_ok { $matrix0->_set_indexes() } qr/ERROR: No index href/, 
    'TESTING DIE ERROR when no arg. was supplied to _set_indexes() function';

throws_ok { $matrix0->_set_indexes('fake') } qr/ERROR: fake supplied/, 
    'TESTING DIE ERROR when arg. supplied to _set_indexes() isnt HASHREF';

throws_ok { $matrix0->_set_indexes({ '1,2' => 1 }) } qr/ERROR: indexN = 1/,
    'TESTING DIE ERROR when arg. supplied to _set_indexes() has diff. expected';


####################
## DATA FUNCTIONS ##
####################

## set_coldata function, TEST 33 to 38

$matrix0->set_coldata(2, [8, 9]);
is(join(',', @{$matrix0->get_data()}), '1,8,3,4,9,6', 
    "testing set_coldata, checking data")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_coldata() } qr/ERROR: No colname/, 
    'TESTING DIE ERROR when no arg. was supplied to set_coldata() function';

throws_ok { $matrix0->set_coldata(2) } qr/ERROR: No column data aref/, 
    'TESTING DIE ERROR when no column data aref. was supplied to set_coldata()';

throws_ok { $matrix0->set_coldata(2, 1) } qr/ERROR: column data aref = 1/, 
    'TESTING DIE ERROR when col. aref. supplied to set_coldata() isnt ARRAYREF';

throws_ok { $matrix0->set_coldata('fake', [1]) } qr/ERROR: fake/, 
    'TESTING DIE ERROR when col. name supplied to set_coldata() doesnt exist';

throws_ok { $matrix0->set_coldata(2, [1]) } qr/ERROR: data supplied/, 
    'TESTING DIE ERROR when data supplied to set_coldata() doesnt have same N';

## set_rowdata function, TEST 39 to 44

$matrix0->set_rowdata('B', [11, 59, 12]);
is(join(',', @{$matrix0->get_data()}), '1,8,3,11,59,12', 
    "testing set_rowdata, checking data")
    or diag("Looks like this has failed");

throws_ok { $matrix0->set_rowdata() } qr/ERROR: No rowname/, 
    'TESTING DIE ERROR when no arg. was supplied to set_rowdata() function';

throws_ok { $matrix0->set_rowdata('B') } qr/ERROR: No row data aref/, 
    'TESTING DIE ERROR when no row data aref. was supplied to set_rowdata()';

throws_ok { $matrix0->set_rowdata('B', 1) } qr/ERROR: row data aref = 1/, 
    'TESTING DIE ERROR when row aref. supplied to set_rowdata() isnt ARRAYREF';

throws_ok { $matrix0->set_rowdata('fake', [1]) } qr/ERROR: fake/, 
    'TESTING DIE ERROR when row. name supplied to set_rowdata() doesnt exist';

throws_ok { $matrix0->set_rowdata('B', [1]) } qr/ERROR: data supplied/, 
    'TESTING DIE ERROR when data supplied to set_rowdata() doesnt have same N';

## add_column, TEST 45 to 50

$matrix0->add_column(4, [12, 34]);
is(join(',', @{$matrix0->get_data()}), '1,8,3,12,11,59,12,34', 
    "testing add_column, checking data")
    or diag("Looks like this has failed");

is($matrix0->get_coln(), 4, 
    "testing add_column, checking new column number")
    or diag("Looks like this has failed");

is($matrix0->get_rown(), 2, 
    "testing add_column, checking row number")
    or diag("Looks like this has failed");

throws_ok { $matrix0->add_column() } qr/ERROR: No column data/, 
    'TESTING DIE ERROR when no column data arg. was supplied to add_column()';

throws_ok { $matrix0->add_column(undef, 'fake') } qr/ERROR: column data/, 
    'TESTING DIE ERROR when column data was supplied to add_column() isnt AREF';

throws_ok { $matrix0->add_column(undef, [1]) } qr/ERROR: element N./, 
    'TESTING DIE ERROR when column elements arent equal to row N';


## add_row, TEST 51 to 56

$matrix0->add_row('C', [15, 98, 37, 1]);
is(join(',', @{$matrix0->get_data()}), '1,8,3,12,11,59,12,34,15,98,37,1', 
    "testing add_row, checking data")
    or diag("Looks like this has failed");

is($matrix0->get_coln(), 4, 
    "testing add_row, checking column number")
    or diag("Looks like this has failed");

is($matrix0->get_rown(), 3, 
    "testing add_row, checking new row number")
    or diag("Looks like this has failed");

throws_ok { $matrix0->add_row() } qr/ERROR: No row data/, 
    'TESTING DIE ERROR when no row data arg. was supplied to add_row()';

throws_ok { $matrix0->add_row(undef, 'fake') } qr/ERROR: row data/, 
    'TESTING DIE ERROR when row data was supplied to add_row() isnt ARRAYREF';

throws_ok { $matrix0->add_row(undef, [1]) } qr/ERROR: element N./, 
    'TESTING DIE ERROR when row elements arent equal to col N';


## delete_column, TEST 57 to 62

my @deleted_col = $matrix0->delete_column(3);
is(join(',', @{$matrix0->get_data()}), '1,8,12,11,59,34,15,98,1',
    "testing delete_column, checking data")
    or diag("Looks like this has failed");

is($matrix0->get_coln(), 3, 
    "testing delete_column, checking new column number")
    or diag("Looks like this has failed");

is($matrix0->get_rown(), 3, 
    "testing delete_column, checking row number")
    or diag("Looks like this has failed");

is(join(',', @deleted_col), '3,12,37',
    "testing delete_column, checkin deleted data")
    or diag("Looks like this has failed");

throws_ok { $matrix0->delete_column() } qr/ERROR: No colname/, 
    'TESTING DIE ERROR when no colname arg. was supplied to delete_column()';

throws_ok { $matrix0->delete_column('fake') } qr/ERROR: fake used for/, 
    'TESTING DIE ERROR when colname supplied to delete_column() doesnt exist';


## delete_column, TEST 63 to 68

my @deleted_row = $matrix0->delete_row('B');
is(join(',', @{$matrix0->get_data()}), '1,8,12,15,98,1',
    "testing delete_row, checking data")
    or diag("Looks like this has failed");

is($matrix0->get_coln(), 3, 
    "testing delete_row, checking column number")
    or diag("Looks like this has failed");

is($matrix0->get_rown(), 2, 
    "testing delete_row, checking new row number")
    or diag("Looks like this has failed");

is(join(',', @deleted_row), '11,59,34',
    "testing delete_row, checkin deleted data")
    or diag("Looks like this has failed");

throws_ok { $matrix0->delete_row() } qr/ERROR: No rowname/, 
    'TESTING DIE ERROR when no rowname arg. was supplied to delete_row()';

throws_ok { $matrix0->delete_row('fake') } qr/ERROR: fake used for/, 
    'TESTING DIE ERROR when rowname supplied to delete_row() doesnt exist';


## Change_columns, TEST 69 to 73

$matrix0->change_columns(1, 4);
is(join(',', @{$matrix0->get_data()}), '12,8,1,1,98,15',
    "testing change_columns, checking data")
    or diag("Looks like this has failed");

is(join(',', @{$matrix0->get_colnames()}), '4,2,1',
    "testing change_columns, checking column names order")
    or diag("Looks like this has failed");

throws_ok { $matrix0->change_columns() } qr/ERROR: no colname1 arg./, 
    'TESTING DIE ERROR when no colname1 arg. was supplied to change_columns()';

throws_ok { $matrix0->change_columns(1) } qr/ERROR: no colname2 arg./, 
    'TESTING DIE ERROR when no colname2 arg. was supplied to change_columns()';

throws_ok { $matrix0->change_columns('fake', 1) } qr/ERROR: one or two/, 
    'TESTING DIE ERROR when colname supplied to change_columns() doesnt exist';


## Change_rows, TEST 74 to 78

$matrix0->change_rows('A', 'C');
is(join(',', @{$matrix0->get_data()}), '1,98,15,12,8,1',
    "testing change_rows, checking data")
    or diag("Looks like this has failed");

is(join(',', @{$matrix0->get_rownames()}), 'C,A',
    "testing change_rows, checking row names order")
    or diag("Looks like this has failed");

throws_ok { $matrix0->change_rows() } qr/ERROR: no rowname1 arg./, 
    'TESTING DIE ERROR when no rowname1 arg. was supplied to change_rows()';

throws_ok { $matrix0->change_rows('C') } qr/ERROR: no rowname2 arg./, 
    'TESTING DIE ERROR when no rowname2 arg. was supplied to change_rows()';

throws_ok { $matrix0->change_rows('fake', 'C') } qr/ERROR: one or two/, 
    'TESTING DIE ERROR when rowname supplied to change_rows() doesnt exist';


#############
## SLICERS ##
#############

## get_column, TEST 79

my @coldata4 = $matrix0->get_column(4);
is(join(',', @coldata4), '1,12', 
    "testing get_column, checking column data")
    or diag("Looks like this has failed");

## get_row, TEST 80

my @rowdataC = $matrix0->get_row('C');
is(join(',', @rowdataC), '1,98,15', 
    "testing get_row, checking row data")
    or diag("Looks like this has failed");

## get_element, TEST 81

my $element4C = $matrix0->get_element('C', 4);
is($element4C, 1, 
    "testing get_element, checking element data")
    or diag("Looks like this has failed");


###########################
## PARSERS AND R.WRITERS ##
###########################

## send_rbase, TEST 82 to 86

my $rih = R::YapRI::Base->new();
push @rih_objs, $rih;

$matrix0->send_rbase($rih);

my $mtxname = $matrix0->get_name();

$rih->create_block('TRANSPOSE_CMD');
my $t_cmd0 = 'transp_' . $mtxname . ' <- t(' . $mtxname . ')';
my $t_cmd1 = 'print(transp_' . $mtxname . ')';
$rih->add_command($t_cmd0, 'TRANSPOSE_CMD');
$rih->add_command($t_cmd1, 'TRANSPOSE_CMD');
$rih->combine_blocks([$mtxname, 'TRANSPOSE_CMD'], 'MTX_TRANS');
$rih->run_commands('MTX_TRANS');
my $resultfile1 = $rih->get_blocks('MTX_TRANS')->get_result_file();

## The original matrix is:
##
##    4  2  1
## C  1 98 15
## A 12  8  1
##
## The transpose should be:
##
##    C  A =====> By_row ==> @mtx = ('\s+C\s+A',
## 4  1 12                           '4\s+1\s+12',
## 2 98  8                           '2\s+98\s+8', 
## 1 15  1                           '1\s+15\s+1');

my @exp_mtx = ('\s+C\s+A', '4\s+1\s+12', '2\s+98\s+8', '1\s+15\s+1');

my $mtx_match = 0;
open my $rfh, '<', $resultfile1;
my $l = 0;
while(<$rfh>) {
    chomp($_);
    if ($_ =~ m/$exp_mtx[$l]/) {
	$mtx_match++;
    }
    $l++;
}

is($mtx_match, 4, 
    "testing send_rbase, checking results after run the commands")
    or diag("Looks like this has failed");

throws_ok { $matrix0->send_rbase() } qr/ERROR: No rbase argument/, 
    'TESTING DIE ERROR when no rbase arg. was supplied to send_rbase()';

throws_ok { $matrix0->send_rbase('fake') } qr/ERROR: fake supplied to/, 
    'TESTING DIE ERROR when rbase arg. supplied to send_rbase() isnt rbase';

my $matrix1 = R::YapRI::Data::Matrix->new();

throws_ok { $matrix1->send_rbase($rih) } qr/ERROR: object R::YapRI::Data::Matr/,
    'TESTING DIE ERROR when object supplied to send_rbase() doesnt have data';

$matrix1->set_coln(2);
$matrix1->set_rown(2);
$matrix1->set_data([1, 2, 3, 4]);

throws_ok { $matrix1->send_rbase($rih) } qr/ERROR: Matrix=R::YapRI::Data::Matr/,
    'TESTING DIE ERROR when object supplied to send_rbase() doesnt have name';


## Check read_rbase, TEST 87 to 97

my $matrix2 = R::YapRI::Data::Matrix->read_rbase( $rih, 
					       'MTX_TRANS', 
					       'transp_' . $mtxname);
my @data2 = @{$matrix2->get_data()};

is(join(',', @data2), '1,12,98,8,15,1',
    "testing read_rbase, checking matrix data")
    or diag("Looks like this has failed");

is(join(',', @{$matrix2->get_colnames()}), 'C,A', 
   "testing read_rbase, checking colnames")
   or diag("Looks like this has failed");

is(join(',', @{$matrix2->get_rownames()}), '4,2,1', 
   "testing read_rbase, checking rownames")
   or diag("Looks like this has failed");

throws_ok { R::YapRI::Data::Matrix->read_rbase() } qr/ERROR: No rbase/, 
    'TESTING DIE ERROR when no rbase arg. was supplied to read_base()';

throws_ok { R::YapRI::Data::Matrix->read_rbase($rih) } qr/ERROR: No block name/,
    'TESTING DIE ERROR when no block arg. was supplied to read_base()';

throws_ok { R::YapRI::Data::Matrix->read_rbase($rih, 'MTX_TRANS') } qr/: No r/, 
    'TESTING DIE ERROR when no r_object arg. was supplied to read_base()';

throws_ok { R::YapRI::Data::Matrix->read_rbase(1, 'MTX_TRANS', 't') } qr/1 obj/,
    'TESTING DIE ERROR when rbase arg. supplied to read_base() isnt r_base';

throws_ok { R::YapRI::Data::Matrix->read_rbase($rih, 'fake', 't') } qr/lock=f/, 
    'TESTING DIE ERROR when block arg. supplied to read_base() doesnt exist';

throws_ok { R::YapRI::Data::Matrix->read_rbase($rih, 'MTX_TRANS', 'fake_obj') } 
   qr/ERROR: fake_obj isnt /, 
    'TESTING DIE ERROR when r_obj supplied to read_base() isnt defined in R';

$rih->add_command('no_mtx <- c(1)', 'MTX_TRANS');

throws_ok { R::YapRI::Data::Matrix->read_rbase($rih, 'MTX_TRANS', 'no_mtx') } 
   qr/ERROR: no_mtx defined /, 
    'TESTING DIE ERROR when r_obj supplied to read_base() isnt R matrix';


## read_ebase with an matrix object without names and with numbers and
## words as elements

my $matrix3 = R::YapRI::Data::Matrix->new({ 
    name => 'mixmatrix',
    rown => 2, 
    coln => 3,
    data => [1, 2, 'Yes', 3, 4, 'No'],
				  });

my $rih2 = R::YapRI::Base->new();
push @rih_objs, $rih2;

$matrix3->send_rbase($rih2);
my $matrix4 = R::YapRI::Data::Matrix->read_rbase($rih2,'mixmatrix','mixmatrix');

is(join(',', @{$matrix4->get_data()}), '1,2,Yes,3,4,No',
    "testing read_rbase for mixed element matrices, checking data")
    or diag("Looks like something has failed");


## no_duplicate_names, TEST 98 to 101

my $matrix_d = R::YapRI::Data::Matrix->new({ 
    name => 'dpl1',
    rown => 2, 
    coln => 2,
    rownames => ["X", "Y"],
    colnames => ["A", "A"],
    data => [1, 2, 3, 4],
				       });

throws_ok { $matrix_d->_no_duplicate_names('col') } qr/ERROR: There are col/, 
    'TESTING DIE ERROR when _no_duplicate_names is used over dupl. cols';

$matrix_d->set_colnames(["A", "B"]);
$matrix_d->set_rownames(["X", "X"]);

throws_ok { $matrix_d->_no_duplicate_names('row') } qr/ERROR: There are row/, 
    'TESTING DIE ERROR when _no_duplicate_names is used over dupl. rows';

throws_ok { $matrix_d->_no_duplicate_names('all') } qr/ERROR: There are dupl/, 
    'TESTING DIE ERROR when _no_duplicate_names is used over dupl. all';

$matrix_d->set_rownames(["X", "Y"]);

lives_ok( sub { $matrix_d->_no_duplicate_names('all') }, 
    'TESTING LIVE when _no_duplicate_names is used over NO dupl. all');

## Check for send_rbase with duplicate names, TEST 102

$matrix_d->set_rownames(["X", "X"]);
throws_ok { $matrix_d->send_rbase($rih2) } qr/ERROR: There are dupl/, 
    'TESTING DIE ERROR when send_rbase is used with duplicates.';


###################
## DATA COMMANDS ##
###################

## Check, _matrix_cmd, TEST 103

my $exp_mtxcmd = $matrix0->get_name();
$exp_mtxcmd .= ' <- matrix(c(1, 98, 15, 12, 8, 1), nrow=2, ';
$exp_mtxcmd .= 'ncol=3, byrow=TRUE, dimnames=list(c("C", "A"), ';
$exp_mtxcmd .= 'c(4, 2, 1)))';
is($matrix0->_matrix_cmd(), $exp_mtxcmd, 
    "testing _matrix_cmd, checking command line")
    or diag("Looks like this has failed");

## Check, _matrix_cmd, TEST 104

my $exp_dtfrcmd = $matrix0->get_name();
$exp_dtfrcmd .= ' <- data.frame( X4=c(1, 12), X2=c(98, 8), X1=c(15, 1), ';
$exp_dtfrcmd .= 'row.names=c("C", "A") )';

is($matrix0->_dataframe_cmd(), $exp_dtfrcmd, 
    "testing _dataframe_cmd, checking command line")
    or diag("Looks like this has failed");

## Check, _rowvectors_cmd, TEST 105

my $exp_rowvect_cmd = 'C <- c(1, 98, 15);A <- c(12, 8, 1)';
is(join(';', @{$matrix0->_rowvectors_cmd()}), $exp_rowvect_cmd, 
    "testing _rowvector_cmd, checking command line")
    or diag("Looks like this has failed");

## Check, _colvectors_cmd, TEST 106

my $exp_colvect_cmd = 'X4 <- c(1, 12);X2 <- c(98, 8);X1 <- c(15, 1)';
is(join(';', @{$matrix0->_colvectors_cmd()}), $exp_colvect_cmd, 
    "testing _colvector_cmd, checking command line")
    or diag("Looks like this has failed");


## Check send_rbase with other modes, TEST 107 to 113

my %modes = (
    matrix         => { $matrix0->get_name() => 'matrix' },
    dataframe      => { $matrix0->get_name() => 'data.frame' },
    vectors_by_row => { C => 'numeric', A => 'numeric' }, 
    vectosr_by_col => { X4 => 'numeric', X2 => 'numeric', X1 => 'numeric' },
    ); 

foreach my $mode (keys %modes) {
    my $rbase_t = R::YapRI::Base->new();
    push @rih_objs, $rbase_t;

    $matrix0->send_rbase($rbase_t, undef, $mode);
   
    foreach my $robj (keys %{$modes{$mode}}) {
	my $class = $rbase_t->r_object_class($matrix0->get_name(), $robj);
	is( $class, $modes{$mode}->{$robj}, 
	    "testing send_rbase with mode=$mode, testing obj class ($robj)")
	    or diag("Looks like this has failed");
    }
}

## Check if it can add a matrix to an existing block

my $nblock1 = 'TESTADDMATRIX1';
$rih2->create_block($nblock1);
$rih2->add_command('xvar <- c(1, 2, 3)', $nblock1);

$matrix0->send_rbase($rih2, $nblock1);

is($rih2->r_object_class($nblock1, 'xvar'), 'numeric', 
    "testing send_rbase to a block, checking old var")
    or diag("Looks like this has failed");

is($rih2->r_object_class($nblock1, $matrix0->get_name()), 'matrix', 
    "testing send_rbase to a block, checking matrix")
    or diag("Looks like this has failed");

throws_ok { $matrix0->send_rbase($rih2, 'fake') } qr/ERROR: fake isnt/, 
    'TESTING DIE ERROR when no defined block is used with send_rbase()';


###############
## TRANSPOSE ##
###############

## TEST 117 to 122

my $mtx5 = R::YapRI::Data::Matrix->new(
    {
	name     => 'mtx5',
	coln     => 3,
	rown     => 2, 
	colnames => ['A', 'B', 'C'],
	rownames => ['X', 'Y'],
	data     => [1, 2, 3, 4, 5, 6],
    });

my $tr_mtx5 = $mtx5->transpose();

is($tr_mtx5->get_name(), 'tr_mtx5',
    "testing transpose, checkin new name")
    or diag("Looks like this has failed");

is($tr_mtx5->get_coln, 2, 
    "testing transpose, checking column number")
    or diag("Looks like this has failed");

is($tr_mtx5->get_rown, 3, 
    "testing transpose, checking row number")
    or diag("Looks like this has failed");

is(join(',', @{$tr_mtx5->get_colnames()}), 'X,Y', 
    "testing transpose, checking column names")
    or diag("Looks like this has failed");

is(join(',', @{$tr_mtx5->get_rownames()}), 'A,B,C', 
    "testing transpose, checking row names")
    or diag("Looks like this has failed");

is(join(',', @{$tr_mtx5->get_data()}), '1,4,2,5,3,6', 
    "testing transpose, checking data")
    or diag("Looks like this has failed");




  
####
1; #
####
