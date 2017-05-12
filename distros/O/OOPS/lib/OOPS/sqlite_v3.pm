
#
# This handles DBD::SQLite 1.x which uses SQLite 3.x
#

package OOPS::sqlite_v3;

@ISA = qw(OOPS::DBO Exporter);
@EXPORT = qw(
	tabledefs
	table_list
	db_initial_values
	initial_query_set
	$big_blob_size
	$retry_count
);

use strict;
use warnings;
use Carp qw(confess);

our $big_blob_size = 900*1024;
our $enable_fd_leak_workaround = 500;
our $invocations = 0;

sub tmode {}

sub lock_object {}

sub deadlock_rx
{
	return (
		qr/database is locked(?:\(\d+\) at dbdimp\.c line )?/,
		qr/unable to open database file\(\d+\) at dbdimp\.c line/,
	);
}

sub nodata_rx
{
	return qr/no such table: \S+object(?:\(1\) at dbdimp\.c)?/;
}

sub initialize
{
	my $dbo = shift;

	my $dbh = $dbo->{dbh};
	$dbh->{sqlite_handle_binary_nulls} = 1;


	# 
	# SQLite will sometimes error out with a locked database
	# error when it should have just waited instead.  Oh well.
	#
	# http://rt.cpan.org/Ticket/Display.html?id=11680
	#
	$dbh->func(10_000, 'busy_timeout');

	my $sync = $dbo->{default_synchronous} || $ENV{OOPS_SYNC};
	if ($sync) {
		my $sm = $dbh->prepare("PRAGMA default_synchronous = $sync;") || confess $dbh->errstr;
		$sm->execute || confess $sm->errstr;
	}

	$dbo->{sqlite_version} = 3;

	return unless $invocations++ >= $enable_fd_leak_workaround;
	return unless $enable_fd_leak_workaround;
	return undef unless -d "/proc/$$/fd";
	return undef unless $dbo->{database} =~ /dbname=(\S+)/;

	my $dbfile = $1;
	my ($dev, $ino) = (stat($dbfile))[0,1];

	my @r;
	local(*D);
	opendir(D, "/proc/$$/fd") || return undef;
	@r = sort { $a <=> $b } grep($_ ne "." && $_ ne "..", readdir(D));
	closedir(D);

	require POSIX;

	pop(@r); pop(@r); pop(@r); pop(@r);

	#
	# The very-recently created sqlite open file is a
	# pipe rather than a link so this won't accidently
	# close it.
	#
	for my $r (@r) {
		next unless $r > $enable_fd_leak_workaround;
		my $f = readlink("/proc/$$/fd/$r");
		next unless $f;
		unless ($f eq $dbfile) {
			my ($fddev, $fdino) = (stat($f))[0,1];
			next unless $fddev == $dev;
			next unless $fdino == $ino;
		}
		warn "Closing fd probably leaked by SQLite ($r);";
		POSIX::close($r);
	}
}

# subroutine
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
		counter		INT,
		gcgeneration	INT DEFAULT 1
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

sub lock
{
	return 1;
}

# subroutine
sub table_list
{
	return (qw(TP_object TP_attribute TP_big));
}

# subroutine
sub db_initial_values
{
	require OOPS::Setup;
	return <<END;
	INSERT INTO TP_object values(100, 100, 'HASH', 'H', 'V', '0', '0', 0, 1, 1, $OOPS::gcgenstart);
	INSERT INTO TP_attribute values(2, 'last reserved object id', $OOPS::last_reserved_oid, 'R');
END
}

sub allocate_id
{
	my $dbo = shift;
	return undef;
}

sub post_new_object
{
	my $dbo = shift;
	return $dbo->{dbh}->func('last_insert_rowid');
}

our $retry_count = 0;

# subroutine
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

sub rebless
{
	my ($dbo, $oops) = @_;
	bless $oops, 'OOPS::sqlite2::subclass';
}

package OOPS::sqlite2::subclass;

use strict;
use warnings;
use Carp;

our @ISA = qw(OOPS Exporter);

sub load_big
{
	my ($oops, $id, $pkey) = @_;
	my $bigloadQ = $oops->query('bigload');
	$bigloadQ->execute($id, $pkey) || confess $bigloadQ->errstr()." ";
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
		$savebigQ->execute($id, $pkey, $fragno, substr($_[0], $fragno * $big_blob_size, $big_blob_size)) || confess;
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

