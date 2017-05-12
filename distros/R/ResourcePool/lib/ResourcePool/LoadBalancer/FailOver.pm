#*********************************************************************
#*** ResourcePool::LoadBalancer::FailOver
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: FailOver.pm,v 1.4 2013-04-16 10:14:44 mws Exp $
#*********************************************************************

package ResourcePool::LoadBalancer::FailOver;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer;

$VERSION = "1.0107";
push @ISA, "ResourcePool::LoadBalancer";

sub get_once($) {
	my ($self) = @_;
	my ($rec, $r_pool);
	my $i = $self->{failover_pos};
	if (! defined $i) {
		$i = 0;
	}
	my $try = $self->{PoolArraySize};

	do {	# get first not suspended pool 
		$r_pool = $self->{PoolArray}->[$i % $self->{PoolArraySize}];
		$i++;
	} while (defined $r_pool && $self->chk_suspend($r_pool) && ($try-- > 0)) ;

	if (defined $r_pool) {	 #
		$rec = $r_pool->{pool}->get();
		if (! defined $rec) {
			$self->suspend($r_pool);
		}

		if (defined $self->{LastUsedPool} && $r_pool != $self->{LastUsedPool}) {
			$self->{LastUsedPool}->{pool}->downsize();
		}
		$self->{LastUsedPool} = $r_pool;
	}
	if (! defined $rec) {
		undef $r_pool;
	}
	$self->{failover_pos} = ($i - 1) % $self->{PoolArraySize};
	return ($rec, $r_pool);
}

sub free_policy($$) {
	my ($self, $r_pool) = @_;

	if ($r_pool != $self->{LastUsedPool}) {
		$self->{LastUsedPool}->{pool}->downsize();
	}
	return 1;
}


1;
