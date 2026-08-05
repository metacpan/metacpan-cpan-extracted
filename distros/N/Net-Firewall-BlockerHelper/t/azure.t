#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper') || print "Bail out!\n";
}

# render the NSG rule's source-address-prefixes from the ban set
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'azure',
		name    => 'ssh',
		testing => 1,
		options => { resource_group => 'rg', nsg => 'mynsg', rule => 'blockrule' },
	);
	$fw->init_backend;
	like( $fw->{test_data}[0], qr/network nsg rule show --resource-group rg --nsg-name mynsg --name blockrule/,
		'init shows the rule' );

	$fw->ban( ban => '1.2.3.4' );
	is( $fw->{test_data},
		'az network nsg rule update --resource-group rg --nsg-name mynsg --name blockrule --source-address-prefixes 1.2.3.4/32',
		'ban updates the rule with the IP as a /32' );

	$fw->ban( ban => '5.6.7.8' );
	is( $fw->{test_data},
		'az network nsg rule update --resource-group rg --nsg-name mynsg --name blockrule --source-address-prefixes 1.2.3.4/32 5.6.7.8/32',
		'second ban renders both prefixes, sorted and space joined' );

	$fw->ban( ban => 'dead::1' );
	like( $fw->{test_data}, qr{dead::1/128}, 'IPv6 rendered as a /128' );

	# CIDR bans share the same rule and are rendered verbatim
	ok( $fw->{backend_obj}{cidr_supported}, 'azure reports cidr_supported' );

	$fw->ban_cidr( ban => '1.2.3.0/24' );
	like( $fw->{test_data}, qr{ 1\.2\.3\.0/24}, 'ban_cidr renders the CIDR into the rule' );
	my %listed = map { $_ => 1 } $fw->list_cidr;
	ok( $listed{'1.2.3.0/24'}, 'ban_cidr adds the CIDR to list_cidr' );

	$fw->unban_cidr( ban => '1.2.3.0/24' );
	my %listed2 = map { $_ => 1 } $fw->list_cidr;
	ok( !$listed2{'1.2.3.0/24'}, 'unban_cidr removes the CIDR from list_cidr' );
}

# custom subscription
{
	my $fw = Net::Firewall::BlockerHelper->new(
		backend => 'azure', name => 'ssh', testing => 1,
		options => { resource_group => 'rg', nsg => 'n', rule => 'r', subscription => 'sub' },
	);
	$fw->init_backend;
	$fw->ban( ban => '9.9.9.9' );
	like( $fw->{test_data}, qr/ --subscription sub$/, 'subscription appended' );
}

# resource_group / nsg / rule are all required
for my $missing (qw(resource_group nsg rule)) {
	my %opts = ( resource_group => 'rg', nsg => 'n', rule => 'r' );
	delete $opts{$missing};
	my $died = 0;
	eval {
		my $fw = Net::Firewall::BlockerHelper->new(
			backend => 'azure', name => 'ssh', testing => 1, options => \%opts,
		);
		$fw->init_backend;
	};
	$died = 1 if ($@);
	ok( $died, "missing $missing is fatal" );
}

done_testing();
