package MyConf;
use utf8;
use v5.30;
use warnings;
use Carp;
use DBI;

use Class::Tiny;
use MyConf::Init;

our $VERSION = 'v1.0.0';

sub get_secret {
	my ($self, $seller_id, $mp_id) = @_;

	my $dbh = $self->_get_dbh;
	my $secret = $dbh->selectrow_hashref(<<SQL, undef, $seller_id, $mp_id, 1);
SELECT
	`mp_seller_id`,
	`secret`
FROM
	`secret`
WHERE
	`seller_id` = ?
	AND `mp_id` = ?
	AND `mode` = ?
	AND `actual` = 1
	ORDER BY `id`
	DESC LIMIT 1
SQL

	return $secret;
}

sub _init_dbh {
	my ($self, $config) = @_;

	my $data_source = sprintf(
		"DBI:mysql:database=%s;host=%s;port=%s",
		$config->{'mysql'}->{'base'},
		$config->{'mysql'}->{'host'},
		$config->{'mysql'}->{'port'},
	);
	return DBI->connect(
		$data_source,
		$config->{'mysql'}->{'user'},
		$config->{'mysql'}->{'pass'},
		{
			PrintError           => 0,
			RaiseError           => 1,
			mysql_enable_utf8mb4 => 1,
		}
	);
}

sub BUILD {
	my ($self) = @_;

	MyConf::Init->init_from_file(); # copy conf from file to env
	$self->{'_dbh'} = $self->_init_dbh(
		{
			mysql => {
				host => $ENV{'MP_HOST'},
				port => $ENV{'MP_PORT'},
				base => $ENV{'MP_BASE'},
				user => $ENV{'MP_USER'},
				pass => $ENV{'MP_PASS'},
			},
		},
	) or confess "Can't connect to value";

	return;
}

sub _get_dbh {
	return shift->{'_dbh'};
}

1;

=encoding UTF-8

=head1 NAME

MyConf - package for working with secrets

=head1 OVERVIEW

Usage example:

	const my $secrets_inst = MyConf->instance;
	...
	my $secrets = $secrets_inst->get_secrets( SELLER_ID, MP_ID );

=head1 DESCRIPTION

The following paths are used for initialization, in order of precedence:

=over

=item

config file located along the path `./conf/locale.conf`

=item

environment variables;

=back
