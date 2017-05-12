package MyDemoServer;

use strict;
use warnings;
use Data::Dumper;

use lib '../lib';
use Net::LDAP::Constant qw(LDAP_SUCCESS);
use Net::LDAP::Server;
use base 'Net::LDAP::Server';
use fields qw();

use constant RESULT_OK => {
	'matchedDN' => '',
	'errorMessage' => '',
	'resultCode' => LDAP_SUCCESS
};

# constructor
sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return $self;
}

# the bind operation
sub bind {
	my $self = shift;
	my $reqData = shift;
	print STDERR Dumper($reqData);
	return RESULT_OK;
}

# the search operation
sub search {
	my $self = shift;
	my $reqData = shift;
	print STDERR "Searching...\n";
	print STDERR Dumper($reqData);
	my $base = $reqData->{'baseObject'};
	
	# plain die if dn contains 'dying'
	die("panic") if $base =~ /dying/;
	
	# return a correct LDAPresult, but an invalid entry
	return RESULT_OK, {test => 1} if $base =~ /invalid entry/;

	# return an invalid LDAPresult
	return {test => 1} if $base =~ /invalid result/;

	my @entries;
	if ($reqData->{'scope'}) {
		# onelevel or subtree
		for (my $i=1; $i<11; $i++) {
			my $dn = "ou=test $i,$base";
			my $entry = Net::LDAP::Entry->new;
			$entry->dn($dn);
			$entry->add(
				dn => $dn,
				sn => 'value1',
				cn => [qw(value1 value2)]
			);
			push @entries, $entry;
		}
		
		my $entry1 = Net::LDAP::Entry->new;
		$entry1->dn("cn=dying entry,$base");
		$entry1->add(
			cn => 'dying entry',
			description => 'This entry will result in a dying error when queried'
		);
		push @entries, $entry1;

		my $entry2 = Net::LDAP::Entry->new;
		$entry2->dn("cn=invalid entry,$base");
		$entry2->add(
			cn => 'invalid entry',
			description => 'This entry will result in ASN1 error when queried'
		);
		push(@entries,$entry2);
		
		my $entry3 = Net::LDAP::Entry->new;
		$entry3->dn("cn=invalid result,$base");
		$entry3->add(
			cn => 'invalid result',
			description => 'This entry will result in ASN1 error when queried'
		);
		push @entries, $entry3;
	} else {
		# base
		my $entry = Net::LDAP::Entry->new;
		$entry->dn($base);
		$entry->add(
			dn => $base,
			sn => 'value1',
			cn => [qw(value1 value2)]
		);
		push @entries, $entry;
	}
	return RESULT_OK, @entries;
}

# the rest of the operations will return an "unwilling to perform"

1;
