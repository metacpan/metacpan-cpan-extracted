
package OOPS::pg;

@ISA = qw(OOPS::DBO);

require OOPS;
use OOPS::DBO;
use strict;
use warnings;
use Carp qw(confess);
use DBD::Pg qw(:pg_types);

BEGIN {
	Filter::Util::Call::filter_add(\&OOPS::SelfFilter::filter)
		unless $OOPS::SelfFilter::defeat;
}

sub tmode
{
	my ($dbo, $dbh) = @_;
	$dbh = $dbo->{dbh} unless $dbh;

	# READ COMMITTED is the default
	# my $tmode2 = $dbo->{counterdbh}->prepare('SET TRANSACTION ISOLATION LEVEL READ COMMITTED') || die;
	# $tmode2->execute() || die $tmode2->errstr;
	unless ($dbo->{readonly}) {
		my $tmode = $dbh->prepare('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE') || die;
		$tmode->execute() || die;
	}
}

#
# Error code that indicates deadlock or clashing transactions.
#
sub deadlock_rx
{
	return (
		qr{ERROR:  could not serialize access due to concurrent update},			  	# pg 8.1
		qr{ERROR:  could not serialize access due to read/write dependencies among transactions}, 	# pg 9.1
		qr{ERROR:  deadlock detected},
		qr{ERROR:  duplicate key value violates unique constraint},     				# pg 9.1
		qr{ERROR:  duplicate key violates unique constraint},						# pg 8.1
	);
}

sub nodata_rx
{
	return qr/ERROR:  relation "\S+object" does not exist/;
}

sub initialize
{
	my ($dbo) = @_;

	# $dbo->tmode;

	$dbo->{counterdbh} = OOPS::dbiconnect(undef, %$dbo);

	$dbo->{id_pool_start} = 0;
	$dbo->{id_pool_end} = 0;
}

#
# Postgres SERIALIZABLE doesn't really work: adding a new
# row that would have been returned by query in another process
# is allowed.  Setting this to 1 forces the object record
# to be updated every time the object contents change.
#
sub do_forcesave { 1 };

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
		gcgeneration	INT DEFAULT 1,
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
		pval		BYTEA,
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
	require OOPS::Setup;
	return <<END;
	INSERT INTO TP_counters values ('objectid', $OOPS::last_reserved_oid + 1);
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


#
# bind_param only has to happen once.
#
sub query
{
	my ($dbo, $q, %args) = @_;

	my $query;
	my $dbh;
	my $sth;
	my $fresh = 0;

	$dbo->query_debug('pg', $q, %args);

	if (($sth = $dbo->{cached_queries}{$q})) {
		# great
		if ($sth->{Active}) {
			print "Query $q was still active\n" if $OOPS::debug_queries;
			delete $dbo->{cached_queries}{$q};
			delete $dbo->{bind_done}{$q};
			return query($dbo, $q, %args);
		}
		if ($dbo->{binary_q_list}{$q} && ! $dbo->{bind_done}{$q}) {
			$fresh = 1;
		}
	} elsif (($query = $dbo->{queries}{$q})) {
		1 while $query =~ s/DBO:CAST:PG2INT\(($pmatch)\)/CAST($1 AS integer)/s;
		1 while $query =~ s/DBO:CAST:PGBYTEA2INT\(($pmatch)\)/CAST(encode($1, 'escape') AS integer)/s;
		1 while $query =~ s/DBO:CAST:PG2BYTEA\(($pmatch)\)/decode(CAST($1 AS text), 'escape')/s;
		die if $query =~ /\bDBO:[A-Z]+:PG/;
		$query = $dbo->clean_query($query);
		$dbh = $args{dbh} || $dbo->{dbh};
		$sth = $dbh->prepare($query) || die $dbh->errstr;
		$dbo->{cached_queries}{$q} = $sth;
		$fresh = 1;
	} else {
		confess "no query <$q>";
	}

	if ($dbo->{binary_q_list}{$q} && ! $dbo->{binary_params}{$q}) {
		$dbo->{binary_params}{$q} = [];
		for my $i (grep($_ > 0, split(' ', $dbo->{binary_q_list}{$q}))) {
			$dbo->{binary_params}{$q}[$i] = 1;
		}
	}


	my $debug_x = ++$dbo->{invoke_count}{$q};
	print $dbo->{binary_q_list}{$q} ? "BINARY: $q - $debug_x/$fresh\n" : "NOT B: $q - $debug_x/$fresh\n"
		if $OOPS::debug_dbd;

	if (exists $args{execute}) {
		my @a = defined($args{execute})
			? (ref($args{execute})
				? @{$args{execute}}
				: $args{execute})
			: ();

		my $e;
		if ($dbo->{binary_params}{$q} && $fresh) {
			for (my $i = 0; $i <= $#a; $i++) {
				if ($dbo->{binary_params}{$q}[$i+1]) {
					$sth->bind_param($i+1, $a[$i], 
						{ pg_type => PG_BYTEA });
				printf "Bind-param %s #%d - binary\n", $q, $i+1 if $OOPS::debug_dbd;
				} else {
					$sth->bind_param($i+1, $a[$i]);
				}
			}
			$dbo->{bind_done}{$q} = 1;
			$sth->execute() or $e = "Could Not Execute '$query' with '@a':" . ($sth->errstr);
		} else {
			$sth->execute(@a) or $e = "could not execute '$query' with '@a':".$sth->errstr;
		}
		if ($e) {
			$e =~ s/\n/\\n /g; # debug
			confess($e);
		}
	} elsif ($dbo->{binary_params}{$q} && $fresh) {
		print "Using wrapper...\n" if $OOPS::debug_dbd;
		return OOPS::pg::sth->new($sth, $q, $dbo->{binary_params}{$q}, \$dbo->{bind_done}{$q});
	}

	return $sth;
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

sub disconnect
{
	my $dbo = shift;
	$dbo->{counterdbh}->disconnect() if $dbo->{counterdbh};
	delete $dbo->{counterdbh};
	$dbo->SUPER::disconnect();
}

package OOPS::pg::sth;

use strict;
use warnings;
use Carp qw(confess);
use DBD::Pg qw(:pg_types);

sub new
{
	my ($pkg, $sth, $q, $binary_params, $doneref) = @_;
	return bless [ $sth, $q, $binary_params, $doneref];
}

sub execute
{
	my ($self, @values) = @_;
	my ($sth, $q, $binary_params, $doneref) = @$self;
	$$doneref = 2;

	for (my $i = 0; $i <= $#values; $i++) {
		die if ref $values[$i];
		if ($binary_params->[$i+1]) {
			$sth->bind_param($i+1, $values[$i], 
				{ pg_type => PG_BYTEA });
			printf "Bind-param %s #%d - binary\n", $q, $i+1 if $OOPS::debug_dbd;
		} else {
			$sth->bind_param($i+1, $values[$i]);
		}
	}
	@$self = ($sth);
	$sth->execute();
}

sub AUTOLOAD
{
	my $self = shift;
	our $AUTOLOAD;
	my $a = $AUTOLOAD;
	$a =~ s/.*:://;
	my $method = $self->[0]->can($a) || $self->[0]->can($AUTOLOAD) || confess "cannot find method $a for $self->[0]";
	&$method($self->[0], @_);
}

1;

