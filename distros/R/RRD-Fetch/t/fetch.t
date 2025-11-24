#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Slurp;
use JSON;

BEGIN {
	use_ok('RRD::Fetch') || print "Bail out!\n";
}

my $tests = 1;

my $which_test = `which rrdtool 2> /dev/null > /dev/null`;
if ( $? == 0 ) {
	$tests++;
	my $worked = 0;
	eval {
		my $rrd_fetch = RRD::Fetch->new( rrd_file => 't/data/ucd_load.rrd' );

		my $by_column   = decode_json( read_file('t/data/ucd_load-20251101-20251102-column.json') );
		my $column_test = $rrd_fetch->fetch_joined( 'by' => 'column', start => '20251101', end => '20251102' );

		if (!defined($column_test->{'success'})){
			die('$column_test->{\'success\'} is undef');
		}elsif( ref($column_test->{'success'}) ne '' ){
			die('ref $column_test->{\'success\'} is not "" but "'.ref($column_test->{'success'}).'"');
		}elsif( $column_test->{'success'} !~ /^[01]$/ ){
			die('$column_test->{\'success\'} !~ /^[01]$/ but "'.$column_test->{'success'}.'"');
		}elsif(!defined($column_test->{'retries'})){
			die('$column_test->{\'retries\'} is undef');
		}elsif( ref($column_test->{'retries'}) ne '' ){
			die('ref $column_test->{\'retries\'} is not "" but "'.ref($column_test->{'retries'}).'"');
		}elsif( $column_test->{'retries'} !~ /^\d+$/ ){
			die('$column_test->{\'retries\'} !~ /^\d+$/ but "'.$column_test->{'retries'}.'"');
		}elsif (!defined($column_test->{'output'})){
			die('$column_test->{\'output\'} is undef');
		}elsif( ref($column_test->{'output'}) ne '' ){
			die('ref $column_test->{\'output\'} is not "" but "'.ref($column_test->{'output'}).'"');
		}elsif( !defined( $column_test->{'columns'} ) ) {
			die('$column_test->{"columns"}) is undef');
		}elsif ( ref( $column_test->{'columns'} ) ne 'ARRAY' ) {
			die( 'ref $column_test->{"columns"}) is not ARRAY but "' . ref( $column_test->{'columns'} ) . '"' );
		}elsif( !defined( $column_test->{'data'} ) ) {
			die('$column_test->{"data"}) is undef');
		}elsif ( ref( $column_test->{'data'} ) ne 'HASH' ) {
			die( 'ref $column_test->{"data"}) is not HASH but "' . ref( $column_test->{'data'} ) . '"' );
		}elsif( !defined( $column_test->{'rows'} ) ) {
			die('$column_test->{"rows"}) is undef');
		}elsif ( ref( $column_test->{'rows'} ) ne 'ARRAY' ) {
			die( 'ref $column_test->{"rows"}) is not ARRAY but "' . ref( $column_test->{'rows'} ) . '"' );
		}

		my $rows_test_int=0;
		while (defined($column_test->{'rows'}[$rows_test_int])) {
			if (ref($column_test->{'rows'}[$rows_test_int]) ne ''){
				die('ref $column_test->{\'rows\'}['.$rows_test_int.'] is not "" but "'.ref($column_test->{'rows'}[$rows_test_int]).'"');
			}elsif ($column_test->{'rows'}[$rows_test_int] ne $by_column->{'rows'}[$rows_test_int]){
				die('$column_test->{\'rows\'}['.$rows_test_int.'] ne $by_column->{\'rows\'}['.$rows_test_int.']');
			}
			
			$rows_test_int++;
		}
		if (defined($by_column->{'rows'}[$rows_test_int])){
			die('$by_column->{\'rows\'}['.$rows_test_int.'] is defined but $column_test->{\'rows\'}['.$rows_test_int.'] is not');
		}

		my $column_test_int = 0;
		while ( defined( $column_test->{'columns'}[$column_test_int] ) ) {
			if ( !defined( $by_column->{'columns'}[$column_test_int] ) ) {
				die(      '$column_test->{\'columns\'}['
						. $column_test_int
						. '] is defined while $by_column->{\'columns\'}['
						. $column_test_int
						. '] is not' );
			}elsif ( ref( $column_test->{'columns'}[$column_test_int] ) ne '' ) {
				die(      'ref($column_test->{\'columns\'}[$column_trest_int]) is '
						. ref( $column_test->{'columns'}[$column_test_int] )
						. ' and not ""' );
			}elsif ( $by_column->{'columns'}[$column_test_int] ne $column_test->{'columns'}[$column_test_int] ) {
				die(      '$column_test->{\'columns\'}['
						. $column_test_int
						. '] and $by_column->{\'columns\'}['
						. $column_test_int
						. '] are not equal... '
						. $column_test->{'columns'}[$column_test_int]
						. ' found while '
						. $by_column->{'columns'}[$column_test_int]
						. ' is expected...' );
			} ## end if ( $by_column->{'columns'}[$column_test_int...])

			my $column = $column_test->{'columns'}[$column_test_int];
			if (!defined($column_test->{'data'}{$column})) {
				die('$column_test->{\'data\'}{'.$column.'} is undef');
			}elsif (ref($column_test->{'data'}{$column}) ne 'ARRAY') {
				die('ref $column_test->{\'data\'}{'.$column.'} is not ARRAY but "'.ref($column_test->{'data'}{$column}).'"');
			}

			$rows_test_int=0;
			while (defined($column_test->{'data'}{$column}[$rows_test_int])){
				if (ref($column_test->{'data'}{$column}[$rows_test_int]) ne '') {
					die('ref $column_test->{\'data\'}{'.$column.'}['.$rows_test_int.'] is not "" but "'.ref($column_test->{'data'}{$column}[$rows_test_int]).'"');
				}elsif ($column_test->{'data'}{$column}[$rows_test_int] ne $by_column->{'data'}{$column}[$rows_test_int]) {
					die('$column_test->{\'data\'}{'.$column.'}['.$rows_test_int.'] ne $by_column->{\'data\'}{'.$column.'}['.$rows_test_int.']');
				}

				$rows_test_int++;
			}
			if (defined($by_column->{'data'}{$column}[$rows_test_int])) {
				die('$by_column->{\'data\'}{'.$column.'}['.$rows_test_int.'] is defined but not in $column_test->{\'data\'}{'.$column.'}['.$rows_test_int.']');
			}

			$column_test_int++;
		} ## end while ( defined( $column_test->{'columns'}[$column_test_int...]))
		if ( defined( $by_column->{'columns'}[$column_test_int] ) ) {
			die(      '$column_test->{\'columns\'}['
					. $column_test_int
					. '] and is not in $by_column->{\'columns\'}['
					. $column_test_int
					. ']' );
		}

		my $by_time   = decode_json( read_file('t/data/ucd_load-20251101-20251102-time.json') );
		my $time_test = $rrd_fetch->fetch_joined( 'by' => 'time', start => '20251101', end => '20251102' );

		if (!defined($time_test->{'success'})){
			die('$time_test->{\'success\'} is undef');
		}elsif( ref($time_test->{'success'}) ne '' ){
			die('ref $time_test->{\'success\'} is not "" but "'.ref($time_test->{'success'}).'"');
		}elsif( $time_test->{'success'} !~ /^[01]$/ ){
			die('$time_test->{\'success\'} !~ /^[01]$/ but "'.$time_test->{'success'}.'"');
		}elsif(!defined($time_test->{'retries'})){
			die('$time_test->{\'retries\'} is undef');
		}elsif( ref($time_test->{'retries'}) ne '' ){
			die('ref $time_test->{\'retries\'} is not "" but "'.ref($time_test->{'retries'}).'"');
		}elsif( $time_test->{'retries'} !~ /^\d+$/ ){
			die('$time_test->{\'retries\'} !~ /^\d+$/ but "'.$time_test->{'retries'}.'"');
		}elsif (!defined($time_test->{'output'})){
			die('$time_test->{\'output\'} is undef');
		}elsif( ref($time_test->{'output'}) ne '' ){
			die('ref $time_test->{\'output\'} is not "" but "'.ref($time_test->{'output'}).'"');
		}elsif( !defined( $time_test->{'columns'} ) ) {
			die('$time_test->{"columns"}) is undef');
		}elsif ( ref( $time_test->{'columns'} ) ne 'ARRAY' ) {
			die( 'ref $time_test->{"columns"}) is not ARRAY but "' . ref( $time_test->{'columns'} ) . '"' );
		}elsif( !defined( $time_test->{'data'} ) ) {
			die('$time_test->{"data"}) is undef');
		}elsif ( ref( $time_test->{'data'} ) ne 'HASH' ) {
			die( 'ref $time_test->{"data"}) is not HASH but "' . ref( $time_test->{'data'} ) . '"' );
		}elsif( !defined( $time_test->{'rows'} ) ) {
			die('$time_test->{"rows"}) is undef');
		}elsif ( ref( $time_test->{'rows'} ) ne 'ARRAY' ) {
			die( 'ref $time_test->{"rows"}) is not ARRAY but "' . ref( $time_test->{'rows'} ) . '"' );
		}

		$column_test_int = 0;
		while ( defined( $time_test->{'columns'}[$column_test_int] ) ) {
			if ( !defined( $by_time->{'columns'}[$column_test_int] ) ) {
				die(      '$time_test->{\'columns\'}['
						. $column_test_int
						. '] is defined while $by_time->{\'columns\'}['
						. $column_test_int
						. '] is not' );
			}elsif ( ref( $column_test->{'columns'}[$column_test_int] ) ne '' ) {
				die(      'ref($time_test->{\'columns\'}[$column_test_int]) is '
						. ref( $time_test->{'columns'}[$column_test_int] )
						. ' and not ""' );
			}elsif ( $by_time->{'columns'}[$column_test_int] ne $time_test->{'columns'}[$column_test_int] ) {
				die(      '$time_test->{\'columns\'}['
						. $column_test_int
						. '] and $by_time->{\'columns\'}['
						. $column_test_int
						. '] are not equal... '
						. $time_test->{'columns'}[$column_test_int]
						. ' found while '
						. $by_time->{'columns'}[$column_test_int]
						. ' is expected...' );
			}
		  
			
			$column_test_int++;
		} ## end while ( defined( $time_test->{'columns'}[$column_test_int...]))
		if ( defined( $by_time->{'columns'}[$column_test_int] ) ) {
			die(      '$time_test->{\'columns\'}['
					. $column_test_int
					. '] and is not in $by_time->{\'columns\'}['
					. $column_test_int
					. ']' );
		}

		$rows_test_int=0;
		while (defined($time_test->{'rows'}[$rows_test_int])) {
			if (ref($time_test->{'rows'}[$rows_test_int]) ne ''){
				die('ref $time_test->{\'rows\'}['.$rows_test_int.'] is not "" but "'.ref($time_test->{'rows'}[$rows_test_int]).'"');
			}elsif ($time_test->{'rows'}[$rows_test_int] ne $by_time->{'rows'}[$rows_test_int]){
				die('$time_test->{\'rows\'}['.$rows_test_int.'] ne $by_time->{\'rows\'}['.$rows_test_int.']');
			}

			my $row=$time_test->{'rows'}[$rows_test_int];
			if (!defined($time_test->{'data'}{$row})){
				die('$time_test->{\'data\'}{'.$row.'} is undef');
			}elsif(ref($time_test->{'data'}{$row}) ne 'HASH'){
				die('ref $time_test->{\'data\'}{'.$row.'} not HASH but is "'.ref($time_test->{'data'}{$row}).'"');
			}

			$column_test_int=0;
			while ( defined( $time_test->{'columns'}[$column_test_int] ) ) {
				my $column = $time_test->{'columns'}[$column_test_int];
				if (!defined($time_test->{'data'}{$row}{$column})){
					die('$time_test->{\'data\'}{'.$row.'}{'.$column.'} is undef');
				}elsif(ref($time_test->{'data'}{$row}{$column}) ne ''){
					die('ref $time_test->{\'data\'}{'.$row.'}{'.$column.'} is not "" but is "'.ref($time_test->{'data'}{$row}{$column}).'"');
				}elsif($time_test->{'data'}{$row}{$column} ne $by_time->{'data'}{$row}{$column}){
					die('time_test->{\'data\'}{'.$row.'}{'.$column.'} ne $by_time->{\'data\'}{'.$row.'}{'.$column.'}');
				}

				$column_test_int++;
			}

			$rows_test_int++;
		}
		if (defined($by_column->{'rows'}[$rows_test_int])){
			die('$by_column->{\'rows\'}['.$rows_test_int.'] is defined but $column_test->{\'rows\'}['.$rows_test_int.'] is not');
		}

		$worked = 1;
	};
	ok( $worked eq '1', 'fetch good' ) or diag( "fetch test failed ... " . $@ );
} ## end if ( $? == 0 )

done_testing($tests);
