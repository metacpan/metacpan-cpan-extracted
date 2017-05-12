
#
# base class for database connectors
#

BEGIN {
	Filter::Util::Call::filter_add(\&OOPS::SelfFilter::filter)
		unless $OOPS::SelfFilter::defeat;
}

package OOPS::DBO;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);
require OOPS::DBOdebug;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(dbiconnect dboconnect $pmatch);

our $backends = qr/(?:mysql|pg|sqlite|sqlite2)/i;

my %loaded;
my %deadlock_rx;

our $pmatch = qr/
	(?:
		[^()]
	|
		\(
			(?:
				[^()]
			|
				\(
					(?:
						[^()]
					|
						\(
							(?:
								[^()]
							|
								\(
									.*?
								\)
							)*?
						\)
					)*?
				\)
			)*?
		\)
	)*?
	/xs;


sub new
{
	my ($pkg, %args) = @_;
	return bless \%args;
}

sub initial_query_set
{
	return '';
}

sub learn_queries
{
	my ($dbo, $Q) = @_;
	while ($Q =~ /\G\t\t([a-z]\w*):((?:\s+\d+)*)\s*(#.*)?\n/gc) {
		my ($qn, $binary_list, $comment) = ($1, $2);
		$dbo->{queries}{$qn} = "";
		while ($Q =~ /\G\t\t\t(.*)\n/gc) {
			$dbo->{queries}{$qn} .= $1."\n";
		}
		$dbo->{binary_q_list}{$qn} = $binary_list;
		$dbo->{debug_q}{$qn} = $comment;
	}
}

sub dbiconnect
{
	my ($pkg, %a) = @_;
	my $args = \%a;
	if (ref($pkg) && ! %a) {
		$args = $pkg->{args} || $pkg;
	}
	my $database = $args->{dbi_dsn} || $args->{DBI_DSN} || $args->{database};
	my $user = $args->{user} || $args->{username} || $args->{USER} || $args->{USERNAME};
	my $password = $args->{pass} || $args->{password} || $args->{PASS} || $args->{PASSWORD};
	my $prefix = $args->{table_prefix} || $args->{TABLE_PREFIX} || $ENV{OOPS_PREFIX} || '';
	$user = $user || $ENV{OOPS_USER} || $ENV{DBI_USER};
	$password = $password || $ENV{OOPS_PASS} || $ENV{DBI_PASS};

	if (! defined($database)) {
		if (defined($ENV{OOPS_DSN})) {
			$database = $ENV{OOPS_DSN};
		} elsif (defined($ENV{DBI_DSN})) {
			$database = $ENV{DBI_DSN} 
		} elsif (defined($ENV{OOPS_DRIVER})) {
			$database = "dbi::$ENV{OOPS_DRIVER}";
		} elsif (defined($ENV{DBI_DRIVER})) {
			$database = "dbi::$ENV{DBI_DRIVER}";
		} else {
			die "no database specified";
		}
	}
	die "only mysql, PostgreSQL & SQLite supported" 
		unless $database =~ /^dbi:($backends)\b/i;
	die "no database specified" unless $database;
	my $dbms = "\L$1";

	my $dbh;
	unless ($args->{no_dbh}) {
		my %a = (
			Taint => 0,
			PrintError => 0,
			AutoCommit => 0,
			RaiseError => 1,
			HandleError => sub { confess(shift) },
		);
		$dbh = DBI->connect($database, $user, $password, \%a)
			or confess "connect to database: $DBI::errstr" unless $dbh;
		$dbh->trace($OOPS::debug_dbi) if $OOPS::debug_dbi;
		$dbh = OOPS::DBO::DBIdebug->new($dbh)
			if $OOPS::debug_queries & 32;
	}

	require "OOPS/$dbms.pm";

	my $dboclass = "OOPS::$dbms";
	unless ($loaded{$dbms}++) {
		my $f = $dboclass->can("deadlock_rx") || die;
		my @dl_rx = $f->();
		@deadlock_rx{@dl_rx} = ($dbms) x @dl_rx;
		my $rx = join('|', keys %deadlock_rx);
		$OOPS::transfailrx = qr/$rx/;
	}

	my $tmode = $dboclass->can("tmode") || die;
	&$tmode(undef, $dbh, $args->{readonly} || 0);

	return $dbh unless wantarray;

	my $new = $dboclass->can("new") || die;
	my $dbo = &$new("OOPS::$dbms",
		table_prefix		=> $prefix,
		database		=> $database,
		user			=> $user,
		password		=> $password,
		readonly		=> $args->{readonly},
		default_synchronous	=> $args->{default_syncronous},
		dbh			=> $dbh,
		dbms			=> $dbms,
	);
	bless $dbo, "OOPS::$dbms";

	$dbo->initialize() unless $args->{no_dbh};

	return ($dbh, $dbms, $prefix, $dbo);
}

sub dboconnect
{
	confess unless @_ % 2 == 1;
	my ($pkg, %a) = @_;
	my ($dbh, $dbms, $prefix, $dbo) = dbiconnect($pkg, %a);
	$dbo->{do_disconnect} = 1;
	return $dbo;
}

sub DESTROY
{
	my $dbo = shift;
	$dbo->disconnect() if $dbo->{do_disconnect};
}

sub clean_query
{
	my ($dbo, $query) = @_;
	$query =~ s/^\s*#.*//mg;
	$query =~ s/#.*debug.*//mg;
	1 while $query =~ s/DBO:\S+?\(($pmatch)\)/$1/gs;
	$query =~ s/TP_/$dbo->{table_prefix}/g;

	if ($query =~ /^\s*:$backends:\s*$/m) {
		my ($before, %map) = split(/^\s*:($backends):\s*$/m, $query);
		$query = $map{$dbo->{dbms}} || $before;
		print "Query selected = $query\n" if $OOPS::debug_queries & 16;
	}
	$query =~ s/\s\s+/ /g;  # mysql query log is easier to debug

	return $query;
}

sub query
{
	my ($dbo, $q, %args) = @_;

	my $query;
	my $dbh;
	my $sth;

	$dbo->query_debug('', $q, %args);

	if (($sth = $dbo->{cached_queries}{$q})) {
		# great
		if ($sth->{Active}) {
			print "Query $q was still active\n" if $OOPS::debug_queries;
			delete $dbo->{cached_queries}{$q};
			return query($dbo, $q, %args);
		}
	} elsif (($query = $dbo->{queries}{$q})) {
		$query = $dbo->clean_query($query);
		$dbh = $args{dbh} || $dbo->{dbh};
		$sth = $dbh->prepare($query) || confess "prepare $query: ".$dbh->errstr;
		$dbo->{cached_queries}{$q} = $sth;
	} else {
		confess;
	}

	if (exists $args{execute}) {
		my @a = defined($args{execute})
			? (ref($args{execute})
				? @{$args{execute}}
				: $args{execute})
			: ();
		$sth->execute(@a) || confess("could not execute '$query' with '@a':".$sth->errstr);
	}
	return $sth;
}

sub adhoc_query
{
	my ($dbo, $query, %args) = @_;
	my $name = $query;
	$name = $1 if $query =~ /^\s*#\s+DBO:name\s+(\S+)/;
	$dbo->{queries}{$name} = $query;
	$dbo->query($name, %args);
}

sub disconnect
{
	my ($dbo) = @_;
	return unless $dbo->{dbh};
	$dbo->{dbh}->disconnect();
	delete $dbo->{dbh};
}

sub commit
{
	my $dbo = shift;
	confess unless $dbo->{dbh};
	$dbo->{dbh}->commit();
}

sub errstr
{
	my $dbo = shift;
	return $DBI::errstr unless $dbo->{dbh};
	return $dbo->{dbh}->errstr;
}

sub dbh
{
	my $dbo = shift;
	return $dbo->{dbh};
}

sub dbo
{
	my $dbo = shift;
	return $dbo;
}

sub rollback
{
	my $dbo = shift;
	$dbo->{dbh}->rollback;
	$dbo->{cached_queries} = {};
}

sub rebless
{
	my $oops = shift;
}

sub do_forcesave { 0; }

1;
