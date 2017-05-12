
package OOPS::OOPS1001::sqlite;

@ISA = qw(OOPS::OOPS1001);

use strict;
use warnings;
use Carp qw(confess);

our $big_blob_size = 900*1024;

# PRAGME integrity_check; ???

sub initialize
{
	my $oops = shift;

	my $dbh = $oops->{dbh};
	$dbh->{sqlite_handle_binary_nulls} = 1;

	if ($oops->{args}{default_synchronous}) {
		my $sm = $dbh->prepare("PRAGMA default_synchronous = $oops->{args}{default_synchronous};") || die;
		$sm->execute || die $sm->errstr;
	}

	#my $tmode = $dbh->prepare('END TRANSACTION; BEGIN TRANSACTION ON CONFLICT ROLLBACK') || die;
	#$tmode->execute() || die $tmode->errstr;
}

sub tabledefs
{
	my $x = <<'END';

	CREATE TABLE TP_object (
		id		INTEGER PRIMARY KEY,
		loadgroup	BIGINT, 
		class 		VARCHAR(255), 		# ref($object)
		otype		CHAR(1),		# 'S'calar/ref, 'A'rray, 'H'ash
		virtual		CHAR(1),		# load virutal ('V' or '0')
		reftarg		CHAR(1),		# reference target ('T' or '0')
		rfe		CHAR(1),		# reserved for future expansion
		alen		INT,			# array length
		refs		INT, 			# references
		counter		SMALLINT
		);

	CREATE INDEX TP_group_index ON TP_object (loadgroup);

	CREATE TABLE TP_attribute (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(128) NOT NULL, 
		pval		VARCHAR(255), 
		ptype		VARCHAR(1),		# type '0'-normal or 'R'eference 'B'ig
		PRIMARY KEY (id, pkey));

	CREATE INDEX TP_value_index ON TP_attribute (pval);

	CREATE TABLE TP_big (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(128) NOT NULL, 
		fragno		INT,
		pval		TEXT,
		PRIMARY KEY (id, pkey, fragno));

END

	$x =~ s/#.*//mg;
	return $x;
}

sub table_list
{
	return (qw(TP_object TP_attribute TP_big));
}

sub db_initial_values
{
	return <<END;
	INSERT INTO TP_object values(100, 100, 'HASH', 'H', 'V', '0', '0', 0, 1, 1);
	INSERT INTO TP_attribute values(2, 'last reserved object id', 100, 'R');
END
}

sub allocate_id
{
	return undef;
}

sub post_new_object
{
	my $oops = shift;
	return $oops->{dbh}->func('last_insert_rowid');
}

sub byebye
{
}

sub initial_query_set
{
	return <<END;
		bigload: 2
			SELECT pval, fragno FROM TP_big 
			WHERE id = ? AND pkey = ?
			ORDER BY fragno
		savebig: 2 3
			INSERT INTO TP_big 
			VALUES (?, ?, ?, ?)
		updatebig: 1 3
			UPDATE TP_big
			SET pval = ?
			WHERE id = ? AND pkey = ?
END
}

sub load_big
{
	my ($oops, $id, $pkey) = @_;
	my $bigloadQ = $oops->query('bigload');
	$bigloadQ->execute($id, $pkey) || die $bigloadQ->errstr()." ";
	my $val;
	my ($frag, $fragno);
	while (($frag, $fragno) = $bigloadQ->fetchrow_array()) {
		$val .= $frag;
	}
	$bigloadQ->finish();
	confess "null big *$id/'$pkey'" if ! defined($val) || $val eq '';
	return $val;
}

sub save_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	my $savebigQ = $oops->query('savebig');
	for (my $fragno = 0; $fragno * $big_blob_size < length($_[0]); $fragno++) {
		$savebigQ->execute($id, $pkey, $fragno, substr($_[0], $fragno * $big_blob_size, $big_blob_size)) || die;
	}
}

sub update_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	$oops->query('deletebig', execute => [ $id, $pkey ]);
	$oops->save_big($id, $pkey, $_[0]);
}

1;

__END__

 
 $dbh->func('last_insert_rowid')


 Remember, SQLite is typeless. A VARCHAR column can hold as much data as any other column. The total amount of data in a single row of the database is limited to 1 megabyte. You can increase this limit to 16 megabytes, if you need to, by adjusting a single #define in the source tree and recompiling.

  

  For maximum speed and space efficiency, you should try to keep the amount of data in a single row below about 230 bytes.

   

   You can declare a table column to be of type "BLOB" but it will still only store null-terminated strings. This is because the only way to insert information into an SQLite database is using an INSERT SQL statement, and you can not include binary data in the middle of the ASCII text string of an INSERT statement.



SQLite is 8-bit clean with regard to the data it stores as long as the data does not contain any '\000' characters. If you want to store binary data, consider encoding your data in such a way that it contains no NUL characters and inserting it that way. You might use URL-style encoding: encode NUL as "%00" and "%" as "%25". Or, you might consider encoding your binary data using base-64. There is a source file named "src/encode.c" in the SQLite distribution that contains implementations of functions named "sqlite_encode_binary() and sqlite_decode_binary() that can be used for converting binary data to ASCII and back again, if you like.

sub allocate_id
{
	my $oops = shift;
	my $id;
	if ($oops->{id_pool_start} && $oops->{id_pool_start} < $oops->{id_pool_end}) {
		$id = $oops->{id_pool_start}++;
		print "in allocate_id, allocating $id from pool\n" if $OOPS::OOPS1001::debug_object_id;
	} else {
		my $allocate_idQ = $oops->query('allocate_id', execute => $OOPS::OOPS1001::id_alloc_size);
		my $get_idQ = $oops->query('get_id', execute => []);
		(($id) = $get_idQ->fetchrow_array) || die $get_idQ->errstr;
		$get_idQ->finish;
		$oops->{id_pool_start} = $id+1;
		$oops->{id_pool_end} = $id+$OOPS::OOPS1001::id_alloc_size;
		print "in allocate_id, new pool: $oops->{id_pool_start} to $oops->{id_pool_end}\n" if $OOPS::OOPS1001::debug_object_id;
		print "in allocate_id, allocated $id from before pool\n" if $OOPS::OOPS1001::debug_object_id;
	}
	return $id;
}

