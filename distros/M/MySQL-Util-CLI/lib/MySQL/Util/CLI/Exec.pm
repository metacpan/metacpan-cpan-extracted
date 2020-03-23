package MySQL::Util::CLI::Exec;
$MySQL::Util::CLI::Exec::VERSION = '0.002';
=head1 NAME

MySQL::Util::CLI::Exec

=head1 VERSION

version 0.002

=cut

use Modern::Perl;
use Moose;
use Kavorka '-all';
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use MySQL::Util::CLI;
use Text::ASCIITable;
use Carp;

with 'Util::Medley::Roles::Attributes::List';

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

has user => (
	is  => 'rw',
	isa => 'Str',
);

has pass => (
	is  => 'rw',
	isa => 'Str',
);

has host => (
	is  => 'rw',
	isa => 'Str',
);

has port => (
	is  => 'rw',
	isa => 'Str',
);

has dbName => (
	is  => 'rw',
	isa => 'Str',
);

has dryRun => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

##############################################################################
# PUBLIC METHODS
##############################################################################

method showDatabases {

	my $cli = $self->_getMysqlUtilCli;
	my @dbs = $cli->getDatabases;

	my $t = Text::ASCIITable->new;
	$t->setCols('DATABASES');

	foreach my $db (@dbs) {
		$t->addRow( $db->[0] );
	}

	print $t;
}

method showGrants (Str :$forUser,
				   Str :$forHost) {

	my $cli    = $self->_getMysqlUtilCli;
	my @grants = $cli->getGrants(@_);

	my $t = Text::ASCIITable->new;
	$t->setCols('GRANTS');

	foreach my $aref (@grants) {
		my $grant = shift @$aref;
		$grant =~ s/identified by password '.+'//i;	
		$t->addRow( $grant );
	}

	print $t;
}

method showUsers {

	my $cli = $self->_getMysqlUtilCli;

	my $sql = "select * from user";
	my $sth = $cli->getDbh->prepare($sql);
	$sth->execute;

	my %users;
	while ( my $href = $sth->fetchrow_hashref ) {
		$users{ $href->{user} } = {%$href};
	}

	my $t = Text::ASCIITable->new;
	$t->setCols( 'USER', 'HOST' );

	foreach my $key ( $self->List->nsort( keys %users ) ) {
		my $href = $users{$key};
		$t->addRow( $href->{user}, $href->{host} );
	}

	print $t;
}

method createUser (Str :$createUser!,
			      Str :$createPass!,
			      Str :$forHosts) {

	my $cli = $self->_getMysqlUtilCli;

	my %p;
	$p{userName} = $createUser;
	$p{userPass} = $createPass;
	$p{hosts}    = [ split( /,/, $forHosts ) ] if $forHosts;

	$cli->createUser(%p);
}

method grantPrivileges (Str :$grantUser!,
						Str :$privileges!,
						Str :$forDbName,
						Str :$forTables,
						Str :$forHosts ) {

	my $cli = $self->_getMysqlUtilCli;

	my %p;
	$p{userName}   = $grantUser;
	$p{privileges} = [ split( /,/, $privileges ) ];
	$p{hosts}      = [ split( /,/, $forHosts ) ] if $forHosts;
	$p{dbName}     = $forDbName if $forDbName;
	$p{tables}     = [ split( /,/, $forTables ) ] if $forTables;

	$cli->grantPrivileges(%p);
}

method revokePrivileges (Str :$revokeUser!,
						Str :$privileges!,
						Str :$forDbName,
						Str :$forTables,
						Str :$forHosts ) {

	my $cli = $self->_getMysqlUtilCli;

	my %p;
	$p{userName}   = $revokeUser;
	$p{privileges} = [ split( /,/, $privileges ) ];
	$p{hosts}      = [ split( /,/, $forHosts ) ] if $forHosts;
	$p{dbName}     = $forDbName if $forDbName;
	$p{tables}     = [ split( /,/, $forTables ) ] if $forTables;

	$cli->revokePrivileges(%p);
}

method dropUser (Str :$dropUser!,
				 Str :$dropHost,
				 Str :$keepHosts) {

	my $cli = $self->_getMysqlUtilCli;

	my %p;
	$p{userName}  = $dropUser;
	$p{host}      = $dropHost if $dropHost;
	$p{keepHosts} = [ split( /,/, $keepHosts ) ] if $keepHosts;

	$cli->dropUser(%p);
}

##############################################################################
# PRIVATE METHODS
##############################################################################

method _getMysqlUtilCli {

	return MySQL::Util::CLI->new( $self->_getAttributeHash );
}

method _getAttributeHash {

	my %a;
	$a{user}   = $self->user   if $self->user;
	$a{pass}   = $self->pass   if $self->pass;
	$a{host}   = $self->host   if $self->host;
	$a{port}   = $self->port   if $self->port;
	$a{dbName} = $self->dbName if $self->dbName;

	return %a;
}

1;
