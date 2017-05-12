
package OOPS::OOPS1003::pg;

@ISA = qw(OOPS::OOPS1003);

use strict;
use warnings;
use Carp qw(confess);

BEGIN {
	Filter::Util::Call::filter_add(\&OOPS::OOPS1003::SelfFilter::filter)
		unless $OOPS::OOPS1003::SelfFilter::defeat;
}

sub initialize
{
	my $oops = shift;

	my $dbh = $oops->{dbh};

	my $tmode = $dbh->prepare('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE') || die;
	$tmode->execute() || die;

	$oops->{counterdbh} = $oops->dbiconnect();
	my $tmode2 = $oops->{counterdbh}->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED') || die;
	$tmode2->execute() || die $tmode2->errstr;

	$oops->{id_pool_start} = 0;
	$oops->{id_pool_end} = 0;

	my $queries = $oops->{queries};
	for my $q (keys %$queries) {
		my $count = ($queries->{$q} =~ tr/?/?/);
		$oops->{param_count}{$q} = $count;
		$oops->{binary_params}{$q} = [];
		for my $i (split(' ',$oops->{binary_q_list}{$q})) {
			next unless $i > 0;
			$oops->{binary_params}{$q}[$i] = 1;
		}
	}
}

sub tabledefs
{
	my $x = <<'END';

	CREATE TABLE TP_object (
		id		BIGINT,
		loadgroup	BIGINT, 
		class 		BYTEA, 			# ref($object)
		otype		CHAR(1),		# 'S'calar/ref, 'A'rray, 'H'ash
		virtual		CHAR(1),		# load virutal ('V' or '0')
		reftarg		CHAR(1),		# reference target ('T' or '0')
		rfe		CHAR(1),		# reserved for future expansion
		alen		INT,			# array length
		refs		INT, 			# references
		counter		SMALLINT,
		PRIMARY KEY (id));

	CREATE INDEX TP_group_index ON TP_object (loadgroup);

	CREATE TABLE TP_attribute (
		id		BIGINT NOT NULL, 
		pkey		BYTEA,
		pval		BYTEA,
		ptype		VARCHAR(1),		# type '0'-normal or 'R'eference 'B'ig
		PRIMARY KEY (id, pkey));

	CREATE INDEX TP_value_index ON TP_attribute (pval);

	CREATE TABLE TP_big (
		id		BIGINT NOT NULL, 
		pkey		BYTEA,
		pval		TEXT,
		PRIMARY KEY (id, pkey));

	CREATE TABLE TP_counters (
		name		VARCHAR(128),
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

sub db_initial_values
{
	return <<END;
	INSERT INTO TP_counters values ('objectid', 101);
END
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
			SELECT DECODE(pval, 'escape') FROM TP_big 
			WHERE id = ? AND pkey = ?
		savebig: 2 3
			INSERT INTO TP_big 
			VALUES (?, ?, ENCODE(?, 'escape'))
		updatebig: 1 3
			UPDATE TP_big
			SET pval = ENCODE(?, 'escape')
			WHERE id = ? AND pkey = ?
END
}

sub query
{
	my ($oops, $q, %args) = @_;

	my $query;
	confess unless $query = $oops->{queries}{$q};
	$query =~ s/TP_/$oops->{table_prefix}/g;

	my $debug_match = $query =~ /$OOPS::debug_q_regex/ 
		|| $oops->{debug_q}{$q} =~ /$OOPS::debug_q_regex/;

	my $dbh = $args{dbh} || $oops->{dbh};
	my $sth = $dbh->prepare_cached($query, undef, 3) || die $dbh->errstr;

	print STDERR "Q1003: $q\n" if ($OOPS::debug_queries & 2) 
		&& (($OOPS::debug_queries & 1) || $debug_match);
	print STDERR "Q1003: $query" if ($OOPS::debug_queries & 4) 
		&& (($OOPS::debug_queries & 1) || $debug_match);

	if (exists $args{execute}) {
		my @a = defined($args{execute})
			? (ref($args{execute})
				? @{$args{execute}}
				: $args{execute})
			: ();

		if ($oops->{binary_params}{$q}) {
			for (my $i = 0; $i <= $#a; $i++) {
				if ($oops->{binary_params}{$q}[$i+1]) {
					$sth->bind_param($i+1, $a[$i], 
						{ pg_type => DBD::Pg::PG_BYTEA });
				} else {
					$sth->bind_param($i+1, $a[$i]);
				}
			}
			$sth->execute() || confess "could not execute '$query' with '@a':".$sth->errstr;
		} else {
			$sth->execute(@a) || confess "could not execute '$query' with '@a':".$sth->errstr;
		}
		print STDERR "A1003: ".join(',', $q, @a)."\n" if ($OOPS::debug_queries & 8) 
			&& (($OOPS::debug_queries & 1) || $debug_match);
	} else {
		print STDERR "A1003: ".join(',', $q, '-none-')."\n" if ($OOPS::debug_queries & 8) 
			&& (($OOPS::debug_queries & 1) || $debug_match);
	}

	return $sth;
}

sub save_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	$oops->query('savebig', execute => [ $id, $pkey, $_[0] ]);
}

sub update_big
{
	my $oops = shift;
	my $id = shift;
	my $pkey = shift;
	my $updatebigQ = $oops->query('updatebig', execute => [ $_[0], $id, $pkey ]);
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

