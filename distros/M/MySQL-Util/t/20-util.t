#!perl

use Modern::Perl;
use String::Util ':all';
use Data::Dumper;
use Test::More qw/no_plan/;
use feature 'state';

use lib '.', './t';

require 'testlib.pl';

BEGIN { use_ok('MySQL::Util'); }

use vars qw($Util);

########################

load_db();

constructor();
verify_auto_commit();
clone_dbh();
get_tables();
use_db_and_get_dbname();
get_depth();
table_exists();
has_ak();
has_fks();
get_indexes();
get_ak_constraint();
get_fk_constraints();
create_data();
drop_fks_and_apply_ddl();
get_ak_indexes();
get_ak_names();
get_fk_indexes();
get_max_depth();
get_other_constraints();
get_other_indexes();
get_pk_index();
is_column_nullable();

##################################

END {
	drop_db();
}

sub get_fk_indexes {
	my $func = ( caller(0) )[3];

	eval { $Util->get_fk_indexes; };
	ok( $@, "$func - no args" );

	my $indexes;
	ok( $indexes = $Util->get_fk_indexes('table_b'), "$func - valid table" );
}

sub get_max_depth {
	my $func = ( caller(0) )[3];

	my $depth;
	ok( $depth = $Util->get_max_depth(), "$func - call without args" );
	ok( $depth == 3, "$func - expected 3, got $depth" );
}

sub get_other_constraints {
	my $func = ( caller(0) )[3];

	eval { $Util->get_other_constraints; };
	ok( $@, "$func - no args" );

	my $cons_href;
	ok( $cons_href = $Util->get_other_constraints('table_b'),
		"$func - valid table" );
}

sub get_other_indexes {
	my $func = ( caller(0) )[3];

	eval { $Util->get_other_indexes; };
	ok( $@, "$func - no args" );

	my $indexes;
	ok( $indexes = $Util->get_other_indexes('table_b'), "$func - valid table" );
}

sub get_pk_index {
	my $func = ( caller(0) )[3];

	eval { $Util->get_pk_index };
	ok( $@, "$func - no args" );

	ok( $Util->get_pk_index('table_a'), "$func - valid table" );
}

sub is_column_nullable {
	my $func = ( caller(0) )[3];

	eval { $Util->is_column_nullable; };
	ok( $@, "$func - no args" );

	ok( $Util->is_column_nullable( table => 'table_a', column => 'tester' ),
		"$func - nullable column" );
	ok( !$Util->is_column_nullable(
			table  => 'table_a',
			column => 'table_a_id'
		),
		"$func - not null column"
	);
}

sub get_ak_names {
	my $func = ( caller(0) )[3];

	eval { $Util->get_ak_names; };
	ok( $@, "$func - no args" );

	my $indexes;
	ok( $indexes = $Util->get_ak_names('table_b'), "$func - valid table" );
}

sub get_ak_indexes {
	my $func = ( caller(0) )[3];

	eval { $Util->get_ak_indexes; };
	ok( $@, "$func - no args" );

	my $indexes;
	ok( $indexes = $Util->get_ak_indexes('table_b'), "$func - valid table" );

	# backwards compatible
	ok( $Util->get_ak_indexs('table_b'), "$func - backwards compatibility" );
}

sub drop_fks_and_apply_ddl {
	my $func = ( caller(0) )[3];

	my $aref = $Util->drop_fks;
	ok( ref $aref eq 'ARRAY',
		"$func - drop_fks, no args, returns an arrayref" );
	ok( scalar @$aref == 5, "$func - arrayref has correct number of elements" );

	my $href = $Util->get_fk_constraints;
	ok( ( scalar keys %$href ) == 0,
		"$func - verify no constraints in the db" );

	ok( $Util->apply_ddl($aref), "$func - apply_ddl" );

	$href = $Util->get_fk_constraints;
	ok( ( scalar keys %$href ) == 5,
		"$func - verify constraints are back in the db" );
}

sub create_data {
	my $func = ( caller(0) )[3];

	eval { $Util->create_data };
	ok( $@, "$func - called without args" );

	my $table = 'depth_0a';
	my $rows  = 20;
	ok( $Util->create_data( table => $table, rows => $rows ) == $rows,
		"$func - simple table and rows" );
	ok( get_row_cnt($table) == $rows, "$func - verify row count" );

	$table = 'depth_1a';
	$rows  = 30;
	ok( $Util->create_data( table => $table, rows => $rows ) == $rows,
		"$func - simple table and rows" );
	ok( get_row_cnt($table) == $rows, "$func - verify row count" );

	$table = 'depth_2a';
	$rows  = 40;
	eval { $Util->create_data( table => $table, rows => $rows ) };
	ok( $@, "$func - todo auto generate data for parent tables if empty" );

	$table = 'depth_0b';
	$rows  = 25;
	ok( $Util->create_data( table => $table, rows => $rows ) == $rows,
		"$func - not so simple table and rows" );
	ok( get_row_cnt($table) == $rows, "$func - verify row count" );

	# try depth_2a again
	$table = 'depth_2a';
	$rows  = 40;
	ok( $Util->create_data( table => $table, rows => $rows ) == $rows,
		"$func - complex table and rows" );
	ok( get_row_cnt($table) == $rows, "$func - verify row count" );

	$table = 'bogus';
	$rows  = 10;
	eval { $Util->create_data( table => $table, rows => $rows ); };
	ok( $@, "$func - called with non-existent table" );

	$table = 'depth_3a';
	$rows  = 50;
	ok( $Util->create_data( table => $table, rows => $rows ) == $rows,
		"$func - complex table and rows" );
	ok( get_row_cnt($table) == $rows, "$func - verify row count" );

	my $dbh = $Util->clone_dbh;
	my $sql = qq{
        select *
        from depth_0a
        };
	my $href = $dbh->selectrow_hashref($sql);
	my $id   = $href->{ uc 'depth_0a_id' };

	ok( $Util->create_data(
			table    => $table,
			rows     => 50,
			defaults => { depth_0a_id => $id }
		),
		"$func - create data with default hint"
	);
}

sub get_row_cnt {
	my $table = shift;

	state $dbh = $Util->clone_dbh;

	my $sql = qq{
        select count(*) from $table
    };

	return $dbh->selectrow_arrayref($sql)->[0];
}

sub get_fk_constraints {
	my $func = ( caller(0) )[3];

	eval { $Util->get_fk_constraints };
	ok( !$@, "$func - called without args" );

	# todo: validate that all fks get returned for the db

	eval { $Util->get_fk_constraints('garbage') };
	ok( $@, "$func - called with garbage" );

	my $fks;
	ok( $fks = $Util->get_fk_constraints('depth_2a'),
		"$func - called with valid table" );

	#  'depth_2a_ibfk_1' => [
	#                         {
	#                           'ORDINAL_POSITION' => '1',
	#                           'COLUMN_NAME' => 'depth_1a_id',
	#                           'REFERENCED_TABLE_NAME' => 'depth_1a',
	#                           'CONSTRAINT_SCHEMA' => 'testmysqlutil',
	#                           'REFERENCED_TABLE_SCHEMA' => 'testmysqlutil',
	#                           'CONSTRAINT_TYPE' => 'FOREIGN KEY',
	#                           'POSITION_IN_UNIQUE_CONSTRAINT' => '1',
	#                           'REFERENCED_COLUMN_NAME' => 'depth_1a_id'
	#                         }
	#                       ],
	#  'depth_2a_ibfk_2' => [
	#                         {
	#                           'ORDINAL_POSITION' => '1',
	#                           'COLUMN_NAME' => 'depth_0b_id',
	#                           'REFERENCED_TABLE_NAME' => 'depth_0b',
	#                           'CONSTRAINT_SCHEMA' => 'testmysqlutil',
	#                           'REFERENCED_TABLE_SCHEMA' => 'testmysqlutil',
	#                           'CONSTRAINT_TYPE' => 'FOREIGN KEY',
	#                           'POSITION_IN_UNIQUE_CONSTRAINT' => '1',
	#                           'REFERENCED_COLUMN_NAME' => 'depth_0b_id'
	#                         }
	#                       ]
	#};

	ok( ref $fks eq 'HASH', "$func - result is a hashref" );
	ok( scalar keys(%$fks) == 2, "$func - result has 2 key" );

	my @constraint_names = keys %$fks;
	ok( defined $fks->{depth_2a_ibfk_1}, "$func - constraint name 1" );
	ok( defined $fks->{depth_2a_ibfk_2}, "$func - constraint name 2" );

	foreach my $constraint_name (qw (depth_2a_ibfk_1 depth_2a_ibfk_2)) {

		my $aref = $fks->{$constraint_name};
		ok( ref $aref eq 'ARRAY', "$func - columns are an arrayref" );
		ok( scalar @$aref == 1, "$func - array elements is 1" );

		foreach my $href (@$aref) {
			my $cnt = keys %$href;
			ok( $cnt == 10, "$func - hash element column count" );
		}

		my $col = $aref->[0];
		ok( $col->{ORDINAL_POSITION} == 1, "$func - ord position" );
		ok( $col->{CONSTRAINT_SCHEMA} eq 'testmysqlutil',
			"$func - constraint schema" );
		ok( $col->{REFERENCED_TABLE_SCHEMA} eq 'testmysqlutil',
			"$func - ref table schema" );
		ok( $col->{CONSTRAINT_TYPE} eq 'FOREIGN KEY',
			"$func - constraint type" );
		ok( $col->{POSITION_IN_UNIQUE_CONSTRAINT} == 1,
			"$func - pos in uniq constraint" );
	}

	my $cname = 'depth_2a_ibfk_1';
	my $col   = $fks->{$cname}->[0];
	ok( $col->{REFERENCED_TABLE_NAME} eq 'depth_1a',
		"$func - $cname ref table name" );
	ok( $col->{COLUMN_NAME} eq 'depth_1a_id', "$func - $cname column name" );
	ok( $col->{REFERENCED_COLUMN_NAME} eq 'depth_1a_id',
		"$func - $cname ref col name" );

	$cname = 'depth_2a_ibfk_2';
	$col   = $fks->{$cname}->[0];
	ok( $col->{REFERENCED_TABLE_NAME} eq 'depth_0b',
		"$func - $cname ref table name" );
	ok( $col->{COLUMN_NAME} eq 'depth_0b_id', "$func - $cname column name" );
	ok( $col->{REFERENCED_COLUMN_NAME} eq 'depth_0b_id',
		"$func - $cname ref col name" );
}

sub get_ak_constraint {
	my $func = ( caller(0) )[3];

	eval { $Util->get_ak_constraints };
	ok( $@, "$func - called without args" );

	eval { $Util->get_ak_constraints('garbage') };
	ok( $@, "$func - called with garbage" );

	my $aks_href;
	ok( $aks_href = $Util->get_ak_constraints('table_b'),
		"$func - called with valid table" );

	ok( ref $aks_href eq 'HASH', "$func - result is a hashref" );
	ok( scalar keys(%$aks_href), "$func - result has 1 key" );

	my @names = sort keys %$aks_href;
	ok( $names[0] eq 'table_b_ak',  "$func - constraint name" );
	ok( $names[1] eq 'table_b_ak2', "$func - constraint name 2" );

	my $aref = $aks_href->{'table_b_ak'};
	ok( ref $aref eq 'ARRAY', "$func - columns are an arrayref" );
	ok( @$aref == 2, "$func - array elements is 2" );

	foreach my $href (@$aref) {
		my $cnt = keys %$href;
		ok( $cnt == 10, "$func - array element column count" );
	}

	my $col_a = shift @$aref;
	ok( $col_a->{ORDINAL_POSITION} == 1, "$func - col_a ord position" );
	ok( !defined $col_a->{REFERENCED_TABLE_NAME},
		"$func - col_a ref table name" );
	ok( $col_a->{COLUMN_NAME} eq 'name', "$func - col_a column name" );
	ok( $col_a->{CONSTRAINT_SCHEMA} eq 'testmysqlutil',
		"$func - col_a constraint schema" );
	ok( !defined $col_a->{REFERENCED_TABLE_SCHEMA},
		"$func - col_a ref table schema" );
	ok( $col_a->{CONSTRAINT_TYPE} eq 'UNIQUE',
		"$func - col_a constraint type" );
	ok( !defined $col_a->{POSITION_IN_UNIQUE_CONSTRAINT},
		"$func - col_a pos in uniq constraint"
	);
	ok( !defined $col_a->{REFERENCED_COLUMN_NAME},
		"$func - col_a ref col name" );

	my $col_b = shift @$aref;
	ok( $col_b->{ORDINAL_POSITION} == 2, "$func - col_b ord position" );
	ok( $col_b->{COLUMN_NAME} eq 'table_a_id', "$func - col_b column name" );
	ok( !defined $col_b->{REFERENCED_TABLE_NAME},
		"$func - col_b ref table name" );
	ok( $col_b->{CONSTRAINT_SCHEMA} eq 'testmysqlutil',
		"$func - col_b constraint schema" );
	ok( !defined $col_b->{REFERENCED_TABLE_SCHEMA},
		"$func - col_b ref table schema" );
	ok( $col_b->{CONSTRAINT_TYPE} eq 'UNIQUE',
		"$func - col_b constraint type" );
	ok( !defined $col_b->{POSITION_IN_UNIQUE_CONSTRAINT},
		"$func - col_b pos in uniq constraint"
	);
	ok( !defined $col_b->{REFERENCED_COLUMN_NAME},
		"$func - col_b ref col name" );
}

sub get_indexes {
	my $func = ( caller(0) )[3];

	eval { $Util->get_indexes };
	ok( $@, "$func - called with no args" );

	eval { $Util->get_indexes('garbage') };
	ok( $@, "$func - called with garbage table" );

	my $i_href = $Util->get_indexes('depth_2a');
	ok( scalar keys(%$i_href) == 2, "$func - index count of 2" );

	foreach my $key ( keys %$i_href ) {

		my $index_aref = $i_href->{$key};
		ok( ref $index_aref eq 'ARRAY', "$func - index is type of array" );

		foreach my $col (@$index_aref) {
			ok( scalar keys(%$col) == 13, "$func - column key count" );
		}
	}

	$i_href = $Util->get_indexes('table_d');
	ok( ref $i_href eq 'HASH',
		"$func - table without indexes returns empty hash" );
	ok( scalar keys(%$i_href) == 0, "$func - hash is empty" );

	# todo: verify some key elements
}

sub has_fks {
	my $func = ( caller(0) )[3];

	eval { $Util->has_fks };
	ok( $@, "$func - without args" );

	eval { $Util->has_fks('garbage') };
	ok( $@, "$func - with garbage arg" );

	ok( !$Util->has_fks('depth_0b'), "$func - depth_0b !has_fks" );
	ok( $Util->has_fks('depth_1a'),  "$func - depth_1a has_fks" );
	ok( $Util->has_fks('depth_2a'),  "$func - depth_2a has_fks" );
}

sub has_ak {
	my $func = ( caller(0) )[3];

	eval { $Util->has_ak };
	ok( $@, "$func - without args" );

	eval { $Util->has_ak('garbage') };
	ok( $@, "$func - with garbage arg" );

	ok( $Util->has_ak('table_a'),  "$func - table_a has_ak" );
	ok( $Util->has_ak('table_b'),  "$func - table_b has_ak" );
	ok( !$Util->has_ak('table_c'), "$func - table_c !has_ak" );
	ok( !$Util->has_ak('table_d'), "$func - table_d !has_ak" );
}

sub verify_auto_commit {
	my $func = ( caller(0) )[3];

	my $dbh  = $Util->_dbh;
	my $auto = $dbh->selectrow_arrayref('select @@autocommit')->[0];
	ok( $dbh->{AutoCommit} == $auto,
		"$func - check AutoCommit for dbd-mysql bug " );
}

sub clone_dbh {
	my $func = ( caller(0) )[3];

	my $dbh = $Util->_dbh;

	my $dbh2;
	ok( $dbh2 = $Util->clone_dbh, "$func - called without args " );
	ok( $dbh->{AutoCommit} == $dbh2->{AutoCommit},
		"$func - AutoCommit is identical for both handles "
	);

	my $auto = $dbh2->selectrow_arrayref('select @@autocommit')->[0];
	ok( $dbh2->{AutoCommit} == $auto,
		"$func - check AutoCommit for dbd-mysql bug " );
}

sub get_tables {
	my $func = ( caller(0) )[3];

	my $tables;
	ok( $tables = $Util->get_tables, "$func - called without args " );
	ok( scalar @$tables == 9, "$func - count " );
	ok( $tables = $Util->get_tables('garbage'), "$func - with args " );
}

sub use_db_and_get_dbname {
	my $func = ( caller(0) )[3];

	my $db = $Util->_schema;
	ok( $Util->get_dbname eq $db, "$func - called without args " );

	eval { $Util->get_dbname('garbage') };
	ok( $@, "$func - called with garbage arg " );

	my $orig_db = $Util->get_dbname;
	ok( $Util->use_db('mysql'), "$func - use_db mysql " );
	ok( $Util->get_dbname eq 'mysql', "$func - get_dbname = mysql " );

	ok( $Util->use_db($orig_db), "$func - use_db $orig_db" );
	ok( $Util->get_dbname eq $orig_db, "$func - get_dbname = $orig_db " );
}

sub table_exists {
	my $func = ( caller(0) )[3];

	eval { $Util->table_exists };
	ok( $@, "$func - called without args " );

	my $table = 'table_a';
	ok( $Util->table_exists($table), "$func - table $table exists " );

	$table = $Util->get_dbname . '.table_a';
	ok( $Util->table_exists($table), "$func -
          fq table $table exists( same db ) "
	);

	my $orig_db = $Util->get_dbname;
	$Util->use_db('mysql');
	ok( $Util->table_exists($table), "$func -
          fq table $table exists( mysql db ) "
	);
	$Util->use_db($orig_db);

	$table = 'garbage';
	ok( !$Util->table_exists($table), "$func - table $table does not exist " );

	$table = 'mysql.garbage';
	ok( !$Util->table_exists($table), "$func - table $table does not exist " );
}

sub get_depth {
	my $func = ( caller(0) )[3];

	eval { $Util->get_depth };
	ok( $@, "$func - called without args " );

	eval { $Util->get_depth('garbage') };
	ok( $@, "$func - called with invalid table " );

	foreach my $t ( @{ $Util->get_tables } ) {
		next unless $t =~ /^depth_(\d+)/;
		my $expected_depth = $1;

		my $d;
		eval { $d = $Util->get_depth($t) };
		ok( !$@, "$func - called with a valid table " );
		ok( $d == $expected_depth, "$func - depth : got = $d, expected =
          $expected_depth "
		);
	}
}

sub constructor {
	my $func = ( caller(0) )[3];
	my %conf = parse_conf();

	eval { MySQL::Util->new };
	ok( $@, "$func - no args " );

	$Util = MySQL::Util->new(
		dsn  => $conf{DBI_DSN},
		user => $conf{DBI_USER},
		pass => $conf{DBI_PASS},
		span => 0
	);
	ok( $Util, "$func - with valid args " );
}
