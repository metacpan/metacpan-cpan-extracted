
package OOPS::mysql;

@ISA = qw(OOPS::DBO);

use strict;
use warnings;

my %version_cache;

sub tmode
{
	my ($dbo, $dbh, $readonly) = @_;
	$dbh = $dbo->{dbh}
		unless $dbh;
	$readonly = $dbo->{readonly}
		if $dbo && ! defined $readonly;

	# SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ is the default for InnoDB
	my $tmode;
	if ($readonly) {
		$tmode = $dbh->prepare('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED') || die $dbh->errstr;
	} else {
		$tmode = $dbh->prepare('SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE') || die $dbh->errstr;
	}
	$tmode->execute() || die $dbh->errstr;
}

#
# These are the error codes that mysql returns when it deadlocks or has
# clashing transactions.
#
sub deadlock_rx
{
	return (
		qr/Deadlock found when trying to get lock/,
		qr/Deadlock found when trying to get lock; try restarting transaction/,
		qr/Lock wait timeout exceeded; try restarting transaction/,
		qr/:Duplicate entry/,
	);
}

sub nodata_rx
{
	return qr/Table '\S+object' doesn't exist/;
}

sub initialize
{
	my $dbo = shift;

	# $dbo->tmode;

	unless ($version_cache{$dbo->{database}}) {
		my $dbh = $dbo->{dbh};
		my $q = $dbo->adhoc_query("SELECT version()") 
			or confess $dbo->{dbh}->errstr();
		$q->execute() or confess $dbo->{dbh}->errstr();
		my ($v) = $q->fetchrow_array();
		$version_cache{$dbo->{database}} = $v;
	}
	$dbo->{mysql_version} = $version_cache{$dbo->{database}};
	unless (defined $dbo->{mysql_for_update}) {
		#
		# 5.0.45-Debian_1ubuntu3.1-log
		# 
		# Somewhere between 5.0.22 and 5.0.45, SERIALIZABLE
		# started working properly.  Before then FOR UPDATE
		# needed to be added to every query.
		#
		my $v = $dbo->{mysql_version};
		$v =~ m/^((?:\d+\.)+\d+)/;
		my $ver = $1;
		die unless $ver;
		my (@ver) = split(/\./, $ver);
		my $cver = $ver[0] + $ver[1] / 1000 + $ver[2] / 1_000_000;
		if ($cver >= 5.000045) {
			$dbo->{mysql_for_update} = 0;
		} else {
			$dbo->{mysql_for_update} = 1;
		}
	}
	$dbo->{counterdbh} = $dbo->dbiconnect(%$dbo, readonly => 1);
	$dbo->{id_pool_start} = 0;
	$dbo->{id_pool_end} = 0;
}

sub disconnect
{
	my ($dbo) = @_;
	$dbo->SUPER::disconnect();
	return unless $dbo->{counterdbh};
	$dbo->{counterdbh}->disconnect();
	delete $dbo->{counterdbh};
}

sub do_forcesave { 1 };

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
		gcgeneration	INT DEFAULT 1,
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

sub clean_query
{
	my ($dbo, $query) = @_;
	if ($query =~ /\bSELECT\b/i && ! $dbo->{readyonly}) {
		$query =~ s/;//;
		if ($dbo->{mysql_for_update}) {
			$query .= " FOR UPDATE"
				unless $query =~ / FOR UPDATE\s*/;
		}
	}
	return $dbo->SUPER::clean_query($query);
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
		lock_object:
			SELECT loadgroup 
			FROM TP_object
			WHERE id = ? FOR UPDATE 
		lock_attribute:
			SELECT ptype
			FROM TP_attribute
			WHERE id = ? AND pkey = ? FOR UPDATE
END
}

sub db_initial_values
{
	require OOPS::Setup;
	return <<END;
	INSERT INTO TP_counters values ('objectid', $OOPS::last_reserved_oid + 1);
END
}

sub allocate_id
{
	my $dbo = shift;
	my $id;
	if ($dbo->{id_pool_start} && $dbo->{id_pool_start} < $dbo->{id_pool_end}) {
		$id = $dbo->{id_pool_start}++;
		print "in allocate_id, allocating $id from pool\n" if $OOPS::debug_object_id;
	} else {
		my $allocate_idQ = $dbo->query('allocate_id', dbh => $dbo->{counterdbh}, execute => $OOPS::id_alloc_size);
		my $get_idQ = $dbo->query('get_id', dbh => $dbo->{counterdbh}, execute => []);
		(($id) = $get_idQ->fetchrow_array) || die $get_idQ->errstr;
		$get_idQ->finish;
		$dbo->{id_pool_start} = $id+1;
		$dbo->{id_pool_end} = $id+$OOPS::id_alloc_size;
		$dbo->{counterdbh}->commit || die $dbo->{counterdbh}->errstr;
		print "in allocate_id, new pool: $dbo->{id_pool_start} to $dbo->{id_pool_end}\n" if $OOPS::debug_object_id;
		print "in allocate_id, allocated $id from before pool\n" if $OOPS::debug_object_id;
	}
	return $id;
}

sub post_new_object
{
	my $dbo = shift;
	return $_[0];
}

sub lock_object
{
	my ($dbo, $id) = @_;
	my $q = $dbo->query('lock_object', execute => [ $id ]);
	(undef) = $q->fetchrow_array;
	$q->finish()
}

sub lock_attribute
{
	my ($dbo, $id, $pkey) = @_;
	my $q = $dbo->query('lock_attribute', execute => [ $id, $pkey ]);
	(undef) = $q->fetchrow_array;
	$q->finish()
}

sub byebye
{
	my $dbo = shift;
	$dbo->{counterdbh}->disconnect() if $dbo->{counterdbh};
}

1;
