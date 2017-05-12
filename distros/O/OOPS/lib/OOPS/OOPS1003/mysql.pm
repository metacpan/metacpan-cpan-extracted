
package OOPS::OOPS1003::mysql;

@ISA = qw(OOPS::OOPS1003);

use strict;
use warnings;

sub initialize
{
	my $oops = shift;

	$oops->{do_forcesave} = 1;

	# SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ is the default for InnoDB

	my $dbh = $oops->{dbh};
	my $tmode = $dbh->prepare('SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE') || die;
	$tmode->execute() || die;

	$oops->{counterdbh} = $oops->dbiconnect();
	$oops->{id_pool_start} = 0;
	$oops->{id_pool_end} = 0;
}

sub tabledefs
{
	my $x = <<'END';

	CREATE TABLE TP_object (
		id		BIGINT NOT NULL,
		loadgroup	BIGINT, 
		class		VARCHAR(255) BINARY,
		otype		CHAR(1),
		virtual		CHAR(1),
		reftarg		CHAR(1),
		rfe		CHAR(1),
		alen		INT,
		refs		INT, 
		counter		SMALLINT,
		PRIMARY KEY	(id), 
		INDEX		TP_group_index (loadgroup)) 
				TYPE = InnoDB;

	CREATE TABLE TP_attribute (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(255) BINARY,
		pval		VARCHAR(255) BINARY, 
		ptype		CHAR(1),
		PRIMARY KEY	(id, pkey),
		INDEX		TP_value_index (pval(15))) 
				TYPE = InnoDB;

	CREATE TABLE TP_big (
		id		BIGINT NOT NULL, 
		pkey		VARCHAR(255) BINARY,
		pval		LONGBLOB,
		PRIMARY KEY	(id, pkey))
				TYPE = InnoDB;

	CREATE TABLE TP_counters (
		name		VARCHAR(128) BINARY,
		cval		BIGINT,
		PRIMARY KEY	(name));


END
	$x =~ s/#.*//mg;
	return $x;
}

sub table_list
{
	return (qw(TP_object TP_attribute TP_big TP_counters));
}

sub initial_query_set
{
	return <<END;
		allocate_id:
			UPDATE TP_counters
			SET cval = cval + ?
			WHERE name = 'objectid'
		get_id:
			SELECT cval 
			FROM TP_counters
			WHERE name = 'objectid'
		bigload: 2
			SELECT pval FROM TP_big 
			WHERE id = ? AND pkey = ?
		savebig: 2 3
			INSERT INTO TP_big 
			VALUES (?, ?, ?)
		updatebig: 1 3
			UPDATE TP_big
			SET pval = ?
			WHERE id = ? AND pkey = ?
END
}

sub db_initial_values
{
	return <<END;
	INSERT INTO TP_counters values ('objectid', 101);
END
}

sub allocate_id
{
	my $oops = shift;
	my $id;
	if ($oops->{id_pool_start} && $oops->{id_pool_start} < $oops->{id_pool_end}) {
		$id = $oops->{id_pool_start}++;
		print "in allocate_id, allocating $id from pool\n" if $OOPS::OOPS1003::debug_object_id;
	} else {
		my $allocate_idQ = $oops->query('allocate_id', dbh => $oops->{counterdbh}, execute => $OOPS::OOPS1003::id_alloc_size);
		my $get_idQ = $oops->query('get_id', dbh => $oops->{counterdbh}, execute => []);
		(($id) = $get_idQ->fetchrow_array) || die $get_idQ->errstr;
		$get_idQ->finish;
		$oops->{id_pool_start} = $id+1;
		$oops->{id_pool_end} = $id+$OOPS::OOPS1003::id_alloc_size;
		$oops->{counterdbh}->commit || die $oops->{counterdbh}->errstr;
		print "in allocate_id, new pool: $oops->{id_pool_start} to $oops->{id_pool_end}\n" if $OOPS::OOPS1003::debug_object_id;
		print "in allocate_id, allocated $id from before pool\n" if $OOPS::OOPS1003::debug_object_id;
	}
	return $id;
}

sub post_new_object
{
	my $oops = shift;
	return $_[0];
}

sub byebye
{
	my $oops = shift;
	$oops->{counterdbh}->disconnect() if $oops->{counterdbh};
}


1;
