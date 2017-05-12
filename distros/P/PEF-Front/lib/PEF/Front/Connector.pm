package PEF::Front::_connector;

use strict;
use warnings;
use base 'DBIx::Connector';
use PEF::Front::Config;

sub _connect {
	my ($self, @args) = @_;
	for (1 .. cfg_db_reconnect_trys) {
		my $dbh = eval {$self->SUPER::_connect(@args)};
		return $dbh if $dbh;
		sleep 1;
	}
	die $@ if $@;
	die "no connect";
}

package PEF::Front::Connector;
use Scalar::Util qw(blessed);
use PEF::Front::Config;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw{db_connect};

our $conn;

my @exported_to;

sub import {
	my ($class, @args) = @_;
	my $callpkg = caller;
	push @exported_to, $callpkg;
	$class->export_to_level(1, $class, @args);
}

sub _db_connector {
	$conn;
}

sub _db_connector_from_pool {
	$conn->get_connector;
}

sub _db_connect {
	my $dbname = cfg_db_name;
	my $dbuser = cfg_db_user;
	my $dbpass = cfg_db_password;
	$dbname = "dbi:Pg:dbname=$dbname" if $dbname !~ /^dbi:/i;
	my %extra_flag = ();
	my ($driver) = $dbname =~ /^dbi:(\w*?)(?:\((.*?)\))?:/i;
	if ($driver) {
		if ($driver eq 'Pg') {
			%extra_flag = (pg_enable_utf8 => 1);
		} elsif ($driver eq 'mysql') {
			%extra_flag = (mysql_enable_utf8 => 1);
		}
	}
	$conn = PEF::Front::_connector->new(
		$dbname, $dbuser, $dbpass,
		{   AutoCommit          => 1,
			PrintError          => 0,
			AutoInactiveDestroy => 1,
			RaiseError          => 1,
			%extra_flag
		}
		)
		or die {
		answer => "SQL_connect: " . DBI->errstr(),
		result => 'INTERR',
		};
	$conn->mode('fixup');
}

sub db_connect {
	no warnings 'redefine';
	if ($_[0] && blessed($_[0])) {
		if ($_[0]->can('get_connector')) {
			$conn       = $_[0];
			*db_connect = \&_db_connector_from_pool;
		} elsif ($_[0]->isa('DBIx::Connector')) {
			*conn       = \$_[0];
			*db_connect = \&_db_connector;
		} else {
			die 'unrecognized argument type';
		}
	} else {
		_db_connect;
		*db_connect = \&_db_connector;
	}
	for my $aep (@exported_to) {
		no strict 'refs';
		*{"$aep\::db_connect"} = \&db_connect;
	}
	goto &db_connect;
}

1;
