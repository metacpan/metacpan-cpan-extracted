package MySQL::Util::CLI;
$MySQL::Util::CLI::VERSION = '0.002';
=head1 NAME

MySQL::Util::CLI

=head1 VERSION

version 0.002

=cut

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use MySQL::Util;
use Carp;
use Data::Printer alias => 'pdump';

with 'Util::Medley::Roles::Attributes::Logger';
with 'Util::Medley::Roles::Attributes::String';

use constant DEFAULT_USER   => 'root';
use constant DEFAULT_PORT   => 3306;
use constant DEFAULT_HOST   => 'localhost';
use constant DEFAULT_DBNAME => 'mysql';

##################################################################

# MYSQL_USER, DBI_USER, USER, DEFAULT_USER
has user => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildUser',
);

# MYSQL_PASS, MYSQL_PWD, or confess
has pass => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildPass',
);

# MYSQL_HOST or DEFAULT_HOST
has host => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildHost',
);

# MYSQL_PORT, MYSQL_TCP_PORT, or DEFAULT_PORT
has port => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildPort',
);

# MYSQL_DBNAME, MYSQL_SCHEMA, or DEFAULT_DBNAME
has dbName => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_buildDbName',
);

has raiseError => (
	is      => 'ro',
	isa     => 'Int',
	default => 1,
);

has printError => (
	is      => 'ro',
	isa     => 'Int',
	default => 0,
);

has fetchHashKeyName => (
	is      => 'ro',
	isa     => 'Str',
	default => 'NAME_lc',
);

has dryRun => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0,
);

##################################################################

has _util => (
	is      => 'rw',
	isa     => 'MySQL::Util',
	lazy    => 1,
	builder => '_buildUtil',
);

has _dbh => (
	is      => 'rw',
	lazy    => 1,
	builder => '_buildDbh',
);

##################################################################

#
# drop all anonymous user entries
# * dropUser(userName => '')
#
# drop all user foo entries
# * dropUser(userName => 'foo')
#
# drop all root entries except '%'
# * dropUser(userName => 'root', keepHosts => ['%'])
#
method dropUser (Str           :$userName!,
			     Str           :$hosts,
			  	 ArrayRef[Str] :$keepHosts) {

	my @sql   = ('select * from user');
	my @where = ('user = ?');
	my @bind  = ($userName);

	if ($hosts) {
		foreach my $host (@$hosts) {
			push @where, 'host = ?';
			push @bind,  $hosts;
		}
	}
	elsif ($keepHosts) {
		foreach my $keepHost (@$keepHosts) {
			push @where, 'host != ?';
			push @bind,  $keepHost;
		}
	}

	push @sql, 'where', join(' and '), @where;
	my $sql = join ' ', @sql;

	$self->Logger->verbose( sprintf 'bind vars: (%s)', join( ', ', @bind ) );
	$self->Logger->verbose($sql);

	my $dbh = $self->getDbh;
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	while ( my $href = $sth->fetchrow_hashref ) {

		my $sql = sprintf q{drop user '%s'@'%s'}, $userName, $href->{host};
		$self->doSql( sql => $sql );
	}

	$self->flushPrivileges;
}

method createDatabase (Str :$dbName!,
					   Bool :$ifNotExists = 1) {

	my @sql = 'create database';
	push @sql, "if not exists" if $ifNotExists;
	push @sql, $dbName;

	$self->doSql( sql => join( ' ', @sql ) );
}

method getGrants (Str :$forUser,
			      Str :$forHost) {

	my @sql = 'show grants';
	if ($forUser) {
		push @sql, "for";
		push @sql, "'$forUser'";
		push @sql, sprintf( "%s'%s'", '@', $forHost ) if $forHost;
	}

	my $dbh = $self->getDbh;
	my $sql = join( ' ', @sql );
	$self->Logger->verbose($sql);
	my $aref = $dbh->selectall_arrayref($sql);

	return @$aref;
}

method getDatabases () {

	my $dbh = $self->getDbh;
	my $sql = "show databases";
	$self->Logger->verbose($sql);
	my $aref = $dbh->selectall_arrayref($sql);

	return @$aref;
}

method userExists (Str :$userName!,
				   Str :$host!) {
	my $sql = q{
		select 
			*
		from 
			user 
		where 
			user = ? and 
			host = ?		   	
		 };

	my $aref =
	  $self->getDbh->selectrow_arrayref( $sql, undef, $userName, $host );

	if ($aref) {
		$self->Logger->verbose("user exists");
		return 1;
	}

	return 0;
}

method grantPrivileges (Str 		 :$userName!,
					   ArrayRef[Str] :$hosts = [DEFAULT_HOST],
					   ArrayRef[Str] :$privileges!,
					   Str           :$dbName = '*',
					   Str 			 :$tables = '*') {

	foreach my $host (@$hosts) {

		my @sql = ('grant');
		push @sql, join( ', ', @$privileges );
		push @sql, 'on';
		push @sql, sprintf( '%s.%s', $dbName, $tables );
		push @sql, 'to';
		push @sql, sprintf( q{'%s'@'%s'}, $userName, $host );

		$self->doSql( sql => join( ' ', @sql ) );
	}

	$self->flushPrivileges;
}

method revokePrivileges (Str 		 :$userName!,
					   ArrayRef[Str] :$hosts = [DEFAULT_HOST],
					   ArrayRef[Str] :$privileges!,
					   Str           :$dbName = '*',
					   Str 			 :$tables = '*') {

	foreach my $host (@$hosts) {

		my @sql = ('revoke');
		push @sql, join( ', ', @$privileges );
		push @sql, 'on';
		push @sql, sprintf( '%s.%s', $dbName, $tables );
		push @sql, 'from';
		push @sql, sprintf( q{'%s'@'%s'}, $userName, $host );

		$self->doSql( sql => join( ' ', @sql ) );
	}

	$self->flushPrivileges;
}

method createUser (Str 		     :$userName!,
			       Str 		     :$userPass!,
			       ArrayRef[Str] :$hosts = []) {

	foreach my $host (@$hosts) {
		if ( !$self->userExists( userName => $userName, host => $host ) ) {
			my $sql = sprintf "create user '%s'\@'%s' identified by '%s'",
			  $userName,
			  $host, $userPass;

			$self->doSql( sql => $sql, );
		}
	}

	$self->flushPrivileges;
}

method getMysqlCli {

	my @cmd = ('mysql');
	push @cmd, '-u', $self->user;
	push @cmd, sprintf '--password="%s"', $self->pass;  # is there a better way?
	push @cmd, '-h', $self->host;
	push @cmd, '-P', $self->port;
	push @cmd, '-D', $self->dbName;

	return join( ' ', @cmd );
}

method printMysqlCli {

	say $self->getMysqlCli;
}

method doSql (Str 	   :$sql!,
			  ArrayRef :$bind = []) {

	my $dbh = $self->getDbh;

	$sql = $self->String->trim($sql);

	$self->Logger->debug( sprintf 'bind vars: (%s)', join( ', ', @$bind ) );
	$self->Logger->verbose($sql);

	if ( !$self->dryRun ) {
		$dbh->do( $sql, undef, @$bind );
	}
}

method flushPrivileges {

	$self->doSql( sql => "flush privileges" );
}

method getMysqlUtil {

	return $self->_util;
}

method getDbh {

	return $self->_dbh;
}

##################################################################

method _buildUser {

	return $ENV{MYSQL_USER} if $ENV{MYSQL_USER};
	return $ENV{DBI_USER}   if $ENV{DBI_USER};
	return $ENV{USER}       if $ENV{USER};
	return DEFAULT_USER;
}

method _buildPass {

	return $ENV{MYSQL_PASS} if $ENV{MYSQL_PASS};
	return $ENV{MYSQL_PWD}  if $ENV{MYSQL_PWD};
	confess "unable to derive a password";
}

method _buildHost {

	return $ENV{MYSQL_HOST} if $ENV{MYSQL_HOST};
	return DEFAULT_HOST;
}

method _buildPort {

	return $ENV{MYSQL_PORT}     if $ENV{MYSQL_PORT};
	return $ENV{MYSQL_TCP_PORT} if $ENV{MYSQL_TCP_PORT};
	return DEFAULT_PORT;
}

method _buildDbName {

	return $ENV{MYSQL_DBNAME} if $ENV{MYSQL_DBNAME};
	return $ENV{MYSQL_SCHEMA} if $ENV{MYSQL_SCHEMA};
	return DEFAULT_DBNAME;
}

method _getNewDbh {

	my @dsn = sprintf 'dbi:mysql:host=%s', $self->host;
	push @dsn, sprintf 'database=%s', $self->dbName;
	push @dsn, sprintf 'port=%s',     $self->port;
	my $dsn = join ';', @dsn;

	my $dbh = DBI->connect(
		$dsn,
		$self->user,
		$self->pass,
		{
			RaiseError => $self->raiseError,
			PrintError => $self->printError,
		}
	);

	$self->Logger->verbose( "connected to $dsn as " . $self->user );

	return $dbh;
}

method _buildDbh {

	my $dbh = $self->_getNewDbh;
	$dbh->{FetchHashKeyName} = $self->fetchHashKeyName;

	return $dbh;
}

method _buildUtil {

	return MySQL::Util->new( dbh => $self->_getNewDbh );
}

1;
