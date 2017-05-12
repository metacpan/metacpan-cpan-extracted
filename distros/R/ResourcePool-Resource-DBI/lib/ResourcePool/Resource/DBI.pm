#*********************************************************************
#*** ResourcePool::Resource::DBI
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: DBI.pm,v 1.3 2004/05/02 07:20:09 mws Exp $
#*********************************************************************

package ResourcePool::Resource::DBI;

use vars qw($VERSION @ISA);
use strict;
use DBI;
use ResourcePool::Resource;

$VERSION = "1.0101";
push @ISA, "ResourcePool::Resource";

sub new($$$$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	my $ds   = shift;
	my $user = shift;
	my $auth = shift;
	my $attr = shift;

	eval {
		$self->{dbh} = DBI->connect($ds, $user, $auth, $attr);
	}; 
	if (! defined $self->{dbh}) {
		warn "ResourcePool::Resource::DBI: Connect to '$ds' failed: $DBI::errstr\n";
		return undef;
	}
	bless($self, $class);

	return $self;
}

sub close($) {
	my ($self) = @_;
	eval {
		$self->{dbh}->disconnect();
	};
}

sub precheck($) {
	my ($self) = @_;	
	my $rc = $self->{dbh}->ping();

	if (!$rc) {
		eval {
			$self->close();
		};
	}
	return $rc;
}

sub postcheck($) {
	my ($self) = @_;

	if (! $self->{dbh}->{AutoCommit}) {
		eval {
			$self->{dbh}->rollback();
		};
	}
	return 1;
}

sub get_plain_resource($) {
	my ($self) = @_;
	return $self->{dbh};
}

sub DESTROY($) {
	my ($self) = @_;
	$self->close();
}

1;
