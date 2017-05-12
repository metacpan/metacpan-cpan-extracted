package POE::Component::Cache;

use strict;
use warnings;
use bytes;

use POE;

our $VERSION = '0.1.1';

sub new()
{
	my ($class) = shift;

	my $name = $class . '->new()';

	die "$name requires an even number of arguments" unless (@_ & 1);
	my %params = @_;

	my $life = delete $params{LifeTime};

	if($life =~ /m$/)
	{
		$life =~ s/m//;
		$life *= 60;

	} elsif ($life =~ /s$/) {

		$life =~ s/s//;
	
	} elsif ($life =~ /^\d+$/) {
		
	} else {

		die "The $name LifeTime parameter must be a".
		" number or a number ending in 's' or 'm'";
	}

	my $alias = delete $params{Alias};

	$alias = defined($alias) ? $alias : 'POCO::CACHE';
	
	POE::Session->create(
		inline_states => {
			_start => \&start,
			_stop  => \&stop,

			store  => \&store,
			retrieve => \&retrieve,
			status => \&status,

			adjust_life => \&adjust_life,

			_cache_death => \&cache_death

		},

		heap => { 
			CONFIG => { 
				life => $life, 
				alias => $alias
			} 
		},

	);

	return undef;
}

sub start()
{
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	$kernel->alias_set($heap->{'CONFIG'}->{'alias'});
	$heap->{'CACHE_TABLE'} = {};
}

sub stop()
{
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	$kernel->alias_remove();
	delete $heap->{'CACHE_TABLE'};
	$kernel->alarm_remove_all();
}

sub store()
{
	my ($kernel, $heap, $key, $ref) = @_[KERNEL, HEAP, ARG0, ARG1];
	
	$heap->{'CACHE_TABLE'}->{$key} = $ref;
	$kernel->delay_set('_cache_death', $heap->{'CONFIG'}->{'life'}, $key);

}

sub retrieve()
{
	my ($heap, $key) = @_[HEAP, ARG0];
	
	return $heap->{'CACHE_TABLE'}->{$key};
}

sub status()
{
	my ($heap, $key) = @_[HEAP, ARG0];

	if(exists($heap->{'CACHE_TABLE'}->{$key}))
	{
		return 1;
		
	} else {

		return 0;
	}
}

sub adjust_life()
{
	my ($heap, $life) = @_[HEAP, ARG0];

	$heap->{'CONFIG'}->{'life'} = $life;

	return;
}

sub cache_death()
{
	my ($heap, $key) = @_[HEAP, ARG0];

	delete $heap->{'CACHE_TABLE'}->{$key};

	return;
}

1;
