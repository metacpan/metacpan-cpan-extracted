#*********************************************************************
#*** ResourcePool::Factory::Net::LDAP
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: LDAP.pm,v 1.5 2003/09/25 17:34:06 mws Exp $
#*********************************************************************

package ResourcePool::Factory::Net::LDAP;
use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Factory;
use ResourcePool::Resource::Net::LDAP;
use Data::Dumper;

push @ISA, "ResourcePool::Factory";
$VERSION = "1.0002";

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

sub mk_singleton_key($) {
	my $d = Data::Dumper->new([$_[0]]);
	$d->Indent(0);
	$d->Terse(1);
	return $d->Dump();
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
