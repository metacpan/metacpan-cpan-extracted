#*********************************************************************
#*** ResourcePool::LoadBalancer
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: LoadBalancer.pm,v 1.39 2013-04-16 10:14:44 mws Exp $
#*********************************************************************

######
# TODO
#
# -> statistics function
# -> DEBUG

package ResourcePool::LoadBalancer;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;
use ResourcePool::Command::Execute;

push @ISA, ("ResourcePool::Command::Execute", "ResourcePool::Singleton");
$VERSION = "1.0107";

sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self;

	$self = $class->SUPER::new($key); # Singleton

	if (! exists($self->{Policy})) {
		$self->{key} = $key;
		$self->{PoolArray} = (); # empty pool list
		$self->{PoolArraySize} = 0; # empty pool list
		$self->{PoolHash} = (); # empty pool hash
		$self->{UsedPool} = (); # mapping from plain_resource to
		                        # rich pool
		$self->{Next} = 0;
		my %options = (
			Policy => "LeastUsage",
			MaxTry => 6,
			MaxExecTry => 6,
			# RoundRobin, LeastUsage, FallBack
			SleepOnFail => [0,1,2,4,8]
		);

		if (scalar(@_) == 1) {
			%options = ((%options), %{$_[0]});
		} elsif (scalar(@_) > 1) {
			%options = ((%options), @_);
		}

		$options{Policy} = uc($options{Policy});
		if ($options{Policy} ne "LEASTUSAGE" && 
			$options{Policy} ne "ROUNDROBIN" &&
			$options{Policy} ne "FAILOVER" &&
			$options{Policy} ne "FAILBACK" &&
			$options{Policy} ne "FALLBACK") {
				$options{Policy} = "LEASTUSAGE";
		}

		if (ref($options{SleepOnFail})) {
			push (@{$options{SleepOnFail}},
				($options{SleepOnFail}->[-1]) x
				($options{MaxTry} - 1 - scalar(@{$options{SleepOnFail}})));
		} else {
			# convinience if you want set SleepOnFail to a scalar
			$options{SleepOnFail}
				= [($options{SleepOnFail}) x ($options{MaxTry} - 1)];
		}
		# truncate list if it is too long
		$#{$options{SleepOnFail}} = $options{MaxTry} - 2;


		$self->{Policy}         = $options{Policy};
		$self->{MaxTry}         = $options{MaxTry} - 1;
		$self->{MaxExecTry}     = $options{MaxExecTry} - 1;
		$self->{StatSuspend}    = 0;
		$self->{StatSuspendAll} = 0;
		$self->{SleepOnFail}    = [reverse @{$options{SleepOnFail}}];

		if ($self->{Policy} eq "ROUNDROBIN") {
			$class .= "::RoundRobin";
		} elsif ( $self->{Policy} eq "LEASTUSAGE") {
			$class .= "::LeastUsage";
		} elsif ( $self->{Policy} eq "FALLBACK") {
			$class .= "::FallBack";
		} elsif ( $self->{Policy} eq "FAILBACK") {
			$class .= "::FailBack";
		} elsif ( $self->{Policy} eq "FAILOVER") {
			$class .= "::FailOver";
		}

		eval "require $class";
		bless($self, $class);
	}
	return $self;
}

sub add_pool($$@) {
	my $self = shift;
	my $pool = shift;

	if (! $self->{PoolHash}->{$pool}) {
		my %rich_pool = (
			pool => $pool,
			BadCount => 0,
			SuspendTrigger	=> 1,
			SuspendTimeout	=> 5,
			Suspended       => 0,
			Weight		=> 100,
			@_,
			UsageCount	=> 0,
			StatSuspend => 0,
			StatSuspendTime => 0	
		);
		push @{$self->{PoolArray}}, \%rich_pool;
		$self->{PoolHash}->{$pool} = \%rich_pool;
		$self->{PoolArraySize}++;
	}
}


sub get($) {
	my ($self) = @_;
	my $rec;
	my $maxtry = $self->{MaxTry};
	my $trylength;
	my $r_pool;

	do {
		$trylength = $self->{PoolArraySize} - $self->{StatSuspend};
		do {
			($rec, $r_pool) = $self->get_once();
		} while (! $rec && ($trylength-- > 0));
	} while (! $rec && ($maxtry-- > 0) && ($self->sleepit($maxtry)));

	if ($rec) {
		$self->{UsedPool}->{$rec} = $r_pool;
	}
	return $rec;
}

sub free($$) {
	my ($self, $rec) = @_;
	return unless defined $rec;
	my $r_pool = $self->{UsedPool}->{$rec};	

	if ($r_pool) {
		$r_pool->{pool}->free($rec);
		undef $self->{UsedPool}->{$rec};
#		if ($self->chk_suspend_no_recover($r_pool)) {
#			$r_pool->{pool}->downsize();
#		}
		return $self->free_policy($r_pool);
	} else {
		return 0;
	}
}

sub free_policy($$) {
	return 1;
}

sub fail($$) {
	my ($self, $rec) = @_;
	my $r_pool = $self->{UsedPool}->{$rec};

	if (defined $r_pool) {
	 	$r_pool->{pool}->fail($rec);	
		undef $self->{UsedPool}->{$rec};
		if (! $self->chk_suspend($r_pool)) {
			$self->suspend($r_pool);
		}
		return 1;
	} else {
		return 0;
	}
}

sub downsize($) {
	my ($self) = @_;
	my $r_pool;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$r_pool->{pool}->downsize();
	}
}

sub info($) {
	my ($self) = @_;

	return $self->{key};
}

sub get_stat_used($) {
	my ($self) = @_;
	my $r_pool;
	my $used = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$used += $r_pool->{pool}->get_stat_used();
	}	
	return $used;
}

sub get_stat_free($) {
	my ($self) = @_;
	my $r_pool;
	my $free = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		$free += $r_pool->{pool}->get_stat_free();
	}	
	return $free;
}
###
# private

sub suspend($$) {
	my ($self, $r_pool) = @_;
	
	if ($r_pool->{SuspendTimeout} <= 0) {
		return;
	}

	if (! $self->chk_suspend_no_recover($r_pool)) {
		swarn("LoadBalancer(%s): Suspending pool to '%s' for %s seconds\n",
			$self->{key},
			$r_pool->{pool}->info(),
			$r_pool->{SuspendTimeout});
		$r_pool->{Suspended} = time + $r_pool->{SuspendTimeout};
		$r_pool->{pool}->downsize();
		$r_pool->{StatSuspend}++;
		$self->{StatSuspend}++;
		$self->{StatSuspendAll}++;
	}
}

sub chk_suspend($$) {
	my ($self, $r_pool) = @_;
#	my $r_pool = $self->{PoolHash}->{$pool};

	if ($self->chk_suspend_no_recover($r_pool)) {
		if ($r_pool->{Suspended} <= time()) {
			$self->{StatSuspend}--;
			$r_pool->{StatSuspendTime} += $r_pool->{SuspendTimeout};
			$r_pool->{StatSuspendTime} += time() - $r_pool->{Suspended};

			$r_pool->{UsageCount} = $self->get_avg_usagecount();
			$r_pool->{Suspended} = 0;
			swarn("LoadBalancer(%s): Recovering pool to '%s'\n",
				$self->{key},
				$r_pool->{pool}->info());
			return 0;
		} else {
			return 1;
		}
	} else {
		return 0;
	}
}

sub chk_suspend_no_recover($$) {
	my ($self, $r_pool) = @_;

	return $r_pool->{Suspended};
}

sub get_avg_usagecount($) {
	my ($self) = @_;
	my $r_pool;
	my $usage_sum = 0;
	my $cnt = 0;

	foreach $r_pool (@{$self->{PoolArray}}) {
		if (! $self->chk_suspend_no_recover($r_pool)) {
			$usage_sum += $r_pool->{UsageCount};
			$cnt++;
		}
	}
	if ($cnt > 0) {
		return $usage_sum / $cnt;
	} else {
		return 0;
	}
}

sub sleepit($$) {
	my ($self, $try) = @_;
	my ($r_pool);

	if ($self->{SleepOnFail}->[$try] > 0) {
		swarn("ResourcePool::LoadBalancer> sleeping %s seconds...\n", 
			$self->{SleepOnFail}->[$try]);
		sleep($self->{SleepOnFail}->[$try]);
	}

	foreach $r_pool (@{$self->{PoolArray}}) {
		$self->chk_suspend($r_pool);
	}
	return 1;
}

sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}

1;
