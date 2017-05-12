#*********************************************************************
#*** ResourcePool::Factory::Alzabo
#*** Copyright (c) 2004 by Texas A&M University <jsmith@cpan.org>
#*** Based on ResourcePool::Factory::DBI
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Alzabo.pm,v 1.1 2004/04/15 20:44:02 jgsmith Exp $
#*********************************************************************

package ResourcePool::Factory::Alzabo;

use vars qw($VERSION @ISA);
use strict;
use ResourcePool::Resource::Alzabo;
use ResourcePool::Factory;

$VERSION = "1.0100";
push @ISA, "ResourcePool::Factory";

sub new($$$$$$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new("Alzabo"); 

	if (! exists($self->{schema})) {
                $self -> {schema} = shift;
		$self->{DS} = shift;
		$self->{user} = shift;
		$self->{auth} = shift;
		$self->{attr} = shift;
	}

	bless($self, $class);

	return $self;
}

sub create_resource($) {
	my ($self) = @_;
	return ResourcePool::Resource::Alzabo->new(	
				$self->{schema}
			,	$self->{DS}
			,	$self->{user}
			,	$self->{auth}
			,	$self->{attr}
	);
}

1;
