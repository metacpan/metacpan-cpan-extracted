package Net::XMPP::Test::Utils;

use strict;
use warnings;

use YAML::Tiny;
use LWP::Online qw/online/;

use Exporter 'import';
our @EXPORT_OK = (qw/
	can_run_tests
	conn_is_available
	accts_are_configured
	bare_jid
	get_conn_params
	get_auth_params
/);

$Net::XMPP::Test::Utils::accounts_file = 't/config/accounts.yml';

sub can_run_tests {
	return conn_is_available() && accts_are_configured();
}

sub conn_is_available {
	return online();
}

sub accts_are_configured {
	return 1
		if -e $Net::XMPP::Test::Utils::accounts_file
			&& -r _ && -s _;
	return 0;
}

sub get_account {
	my ($wanted_account) = @_;

	$Net::XMPP::Test::Utils::accounts
		= YAML::Tiny->read( $Net::XMPP::Test::Utils::accounts_file )
			unless defined $Net::XMPP::Test::Utils::accounts;

	return $Net::XMPP::Test::Utils::accounts->[0]->{$wanted_account};
}

sub bare_jid {
	return get_account( shift )->{'bare_jid'};
}

sub get_conn_params {
	return get_account( shift )->{'conn'};
}

sub get_auth_params {
	my $resource = time . int(rand(1000));
	chomp($resource);

	my $account = get_account( shift )->{'auth'};
	$account->{'resource'} = $resource;

	return $account;
}

1;
