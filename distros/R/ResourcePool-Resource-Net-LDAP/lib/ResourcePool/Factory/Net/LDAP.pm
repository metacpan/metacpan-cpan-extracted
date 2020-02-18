#*********************************************************************
#*** ResourcePool::Factory::Net::LDAP
#*** Copyright (c) 2020 by Markus Winand <mws@fatalmind.com>
#*** $Id$
#*********************************************************************

package ResourcePool::Factory::Net::LDAP;
use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Factory;
use ResourcePool::Resource::Net::LDAP;
use Data::Dumper;

push @ISA, "ResourcePool::Factory";
$VERSION = "1.0003";

####
# Some notes about the singleton behavior of this class.
# 1. the constructor does not return a singleton reference!
# 2. there is a seperate function called singelton() which will return a
#    singleton reference
# this change was introduces with ResourcePool 0.9909 to allow more flexible
# factories (e.g. factories which do not require all parameters to their 
# constructor) an example of such an factory is the Net::LDAP factory.

sub new($@) {
	my ($proto) = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();

	if (! exists($self->{host})) {
        	$self->{host} = shift;
		if (defined $_[0] && ref($_[0]) ne "ARRAY") {
			$self->{BindOptions} = [];
			$self->{NewOptions}  = [@_];
		} else {
			# old syntax, compatiblity...
			$self->{BindOptions} = defined $_[0]?shift: [];
			$self->{NewOptions}  = defined $_[0]?shift: [];
		}
	}
	
	bless($self, $class);

	return $self;
}

sub bind($@) {
	my $self = shift;
	$self->{BindOptions} = [@_];
}

sub start_tls($@) {
	my $self = shift;
	$self->{start_tlsOptions} = [@_];
}

sub create_resource($) {
	my ($self) = @_;
	return ResourcePool::Resource::Net::LDAP->new($self 	
			,	$self->{host}
			,	$self->{BindOptions}
			,	$self->{NewOptions}
			,	$self->{start_tlsOptions}
	);
}

sub info($) {
	my ($self) = @_;
	my $dn;

	if (scalar(@{$self->{BindOptions}}) % 2 == 0) {
		# even numer -> old Net::LDAP->bind syntax
		my %h = @{$self->{BindOptions}};
		$dn = $h{dn};
	} else {
		# odd numer -> new Net::LDAP->bind syntax
		$dn = $self->{BindOptions}->[0];	
	}
	# if dn is still undef -> anonymous bind
	return (defined $dn? $dn . "@" : "" ) . $self->{host};
}


1;
