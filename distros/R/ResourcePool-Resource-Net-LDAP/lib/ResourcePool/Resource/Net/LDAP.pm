#*********************************************************************
#*** ResourcePool::Resource::Net::LDAP
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: LDAP.pm,v 1.5 2003/09/25 17:34:08 mws Exp $
#*********************************************************************

package ResourcePool::Resource::Net::LDAP;

use vars qw($VERSION @ISA);
use strict;
use Net::LDAP qw(LDAP_SUCCESS);
use ResourcePool::Resource;

$VERSION = "1.0002";
push @ISA, "ResourcePool::Resource";

sub new($$$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	$self->{Factory} = shift;
	my $host   = shift;
	$self->{BindOptions} = defined $_[0] ? shift: [];
	my $NewOptions = defined $_[0] ? shift: [];
	$self->{start_tlsOptions} = shift;

	$self->{ldaph} = Net::LDAP->new($host, @{$NewOptions});
	if (! defined $self->{ldaph}) {
		swarn("ResourcePool::Resource::Net::LDAP: ".
			"Connect to '%s' failed: $@\n", 
			$self->{Factory}->info());
		return undef;
	}
	
	bless($self, $class);

	if (! defined $self->start_tls($self->{start_tlsOptions})) {
		return undef;
	} 
	# bind returns $self on success
	return $self->bind($self->{BindOptions});
}

sub close($) {
	my ($self) = @_;
	#$self->{ldaph}->unbind();
}

sub fail_close($) {
	my ($self) = @_;
	swarn("ResourcePool::Resource::Net::LDAP: ".
		"closing failed connection to '%s'.\n",
		$self->{Factory}->info());
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{ldaph};
}

sub DESTROY($) {
	my ($self) = @_;
	$self->close();
}

sub precheck($) {
	my ($self) = @_;
	return $self->bind($self->{BindOptions});
}

sub start_tls($$) {
	my ($self, $tlsoptions) = @_;
	if (defined $tlsoptions) {
		my $rc = $self->{ldaph}->start_tls(@{$tlsoptions});
		if ($rc->code != LDAP_SUCCESS) {
			swarn("ResourcePool::Resource::Net::LDAP: "
				. "start_tls to '%s' failed: %s\n"
				, $self->{Factory}->info()
				, $rc->error()
			);
			delete $self->{ldaph};
			return undef;
		}
	}
	return $self;
}


sub bind($$) {
	my ($self, $bindopts) = @_;
	my @BindOptions = @{$bindopts};
	my $rc;
	
	$rc = $self->{ldaph}->bind(@BindOptions);

	if ($rc->code != LDAP_SUCCESS) {
		swarn("ResourcePool::Resource::Net::LDAP: ".
			"Bind to '%s' failed: %s\n",
			$self->{Factory}->info(),
			$rc->error());
		delete $self->{ldaph};
		return undef;
	}

	return $self;
}


sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}
1;
