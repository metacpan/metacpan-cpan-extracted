#*********************************************************************
#*** ResourcePool
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: ResourcePool.pm,v 1.54 2013-04-16 10:14:43 mws Exp $
#*********************************************************************

######
# TODO
#
# -> statistics function
# -> DEBUG option to find "lost" resources (store backtrace of get() call
#    and dump on DESTROY)
# -> NOTIFYing features

package ResourcePool;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;
use ResourcePool::Command::Execute;

BEGIN { 
	# make script using Time::HiRes, but not fail if it isn't there
	eval "use Time::HiRes qw(sleep)";
}


push @ISA, ("ResourcePool::Command::Execute", "ResourcePool::Singleton");
$VERSION = "1.0107";
 
sub new($$@) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $factory = shift->singleton();
	my $self = $class->SUPER::new($factory); # Singleton

	if (!exists($self->{Factory})) {
		$self->{Factory} = $factory;
		$self->{FreePool} = [];
		$self->{UsedPool} = {};
		$self->{FreePoolSize} = 0;
		$self->{UsedPoolSize} = 0;
		my %options = (
			Max => 5,
			Min => 1,
			MaxTry => 2,
			MaxExecTry => 2,
			PreCreate => 0,
			SleepOnFail => [0]
		);
		if (scalar(@_) == 1) {
			%options = ((%options), %{$_[0]});
		} elsif (scalar(@_) > 1) {
			%options = ((%options), @_);
		}

		if ($options{MaxTry} <= 1) {
			$options{MaxTry} = 2;
		}
		# prepare SleepOnFail parameter, extend if neccessary
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
		
		$self->{Max}         = $options{Max};
		$self->{Min}         = $options{Min};
		$self->{MaxTry}      = $options{MaxTry} - 1;
		$self->{MaxExecTry}  = $options{MaxExecTry} - 1;
		$self->{PreCreate}   = $options{PreCreate};
		$self->{SleepOnFail} = [reverse @{$options{SleepOnFail}}];

		bless($self, $class);
		for (my $i = $self->{PreCreate}; $i > 0; $i--) {
			$self->inc_pool();
		}
	} 
 
	return $self;
}

sub get($) {
	my ($self) = @_;
	my $rec = undef;
	my $maxtry = $self->{MaxTry};
	my $rv = undef;

	do {
		if (! $self->{FreePoolSize}) {
			$self->inc_pool();
		}
		if ($self->{FreePoolSize}) {
			$rec = shift @{$self->{FreePool}};
			$self->{FreePoolSize}--;

			if (! $rec->precheck()) {
				swarn("ResourcePool(%s): precheck failed\n",
					$self->{Factory}->info());
				$rec->fail_close();
				undef $rec;
			}
			if ($rec) {
				$rv = $rec->get_plain_resource();
				$self->{UsedPool}->{$rv} = $rec;
				$self->{UsedPoolSize}++;
			}
		} 
	} while (! $rec &&  ($maxtry-- > 0) && ($self->sleepit($maxtry)));
	return $rv;
}

sub free($$) {
	my ($self, $plain_rec) = @_;

	my $rec = $self->{UsedPool}->{$plain_rec};
	if ($rec) {
		undef $self->{UsedPool}->{$plain_rec};
		$self->{UsedPoolSize}--;
		if ($rec->postcheck()) {
			push @{$self->{FreePool}}, $rec;
			$self->{FreePoolSize}++;
		} else {
			$rec->fail_close();
		}
		return 1;
	} else {
		return 0;
	}
}

sub fail($$) {
	my ($self, $plain_rec) = @_;

	swarn("ResourcePool(%s): got failed resource from client\n",
		$self->{Factory}->info());
	my $rec = $self->{UsedPool}->{$plain_rec};
	if (defined $rec) {
		undef $self->{UsedPool}->{$plain_rec};
		$self->{UsedPoolSize}--;
		$rec->fail_close();
		return 1;
	} else {
		return 0;
	}
}

sub downsize($) {
	my ($self) = @_;
	my $rec;

	swarn("ResourcePool(%s): Downsizing\n", $self->{Factory}->info());
	while ($rec =  shift(@{$self->{FreePool}})) {
		$rec->close();
	}
	$self->{FreePoolSize} = 0;
	swarn("ResourcePool: Downsized... still %s open (%s)\n",
		$self->{UsedPoolSize}, $self->{FreePoolSize});
	
}

sub postfork($) {
	my ($self) = @_;
	my $rec;
	$self->{FreePool} = [];
	$self->{UsedPool} = {};
	$self->{FreePoolSize} = 0;
	$self->{UsedPoolSize} = 0;
}

sub info($) {
	my ($self) = @_;
	return $self->{Factory}->info();
}

sub setMin($$) {
	my ($self, $min) = @_;
	$self->{Min} = $min;
	return 1;
}

sub setMax($$) {
	my ($self, $max) = @_;
	$self->{Max} = $max;
	return 1;
}

sub print_status($) {
	my ($self) = @_;
	printf("\t\t\t\t\tDB> FreePool: <%d>", $self->{FreePoolSize});
	printf(" UsedPool: <%d>\n", $self->{UsedPoolSize});
}

sub get_stat_used($) {
	my ($self) = @_;
	return $self->{UsedPoolSize};
}

sub get_stat_free($) {
	my ($self) = @_;
	return $self->{FreePoolSize};
}

#*********************************************************************
#*** Private Part
#*********************************************************************

sub inc_pool($) {
	my ($self) = @_;
	my $rec;	
	my $PoolSize;

	$PoolSize=$self->{FreePoolSize} + $self->{UsedPoolSize};

	if ( (! defined $self->{Max}) || ($PoolSize < $self->{Max})) {
		$rec = $self->{Factory}->create_resource();
	
		if (defined $rec) {
			push @{$self->{FreePool}}, $rec;
			$self->{FreePoolSize}++;
		}	
	}
}

sub sleepit($$) {
	my ($self, $try) = @_;
	swarn("ResourcePool> sleeping %s seconds...\n", $self->{SleepOnFail}->[$try]);
	sleep($self->{SleepOnFail}->[$try]);
	$self->downsize();
	return 1;
}


#*********************************************************************
#*** Functional Part
#*********************************************************************

sub swarn($@) {
	my $fmt = shift;
	warn sprintf($fmt, @_);
}

1;
