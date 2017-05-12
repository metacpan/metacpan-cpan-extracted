#*********************************************************************
#*** ResourcePool::Factory
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: Factory.pm,v 1.34 2013-04-16 10:14:44 mws Exp $
#*********************************************************************

package ResourcePool::Factory;

use strict;
use vars qw($VERSION @ISA);
use ResourcePool::Singleton;
use ResourcePool::Resource;
use Data::Dumper;

push @ISA, "ResourcePool::Singleton";
$VERSION = "1.0107";

####
# Some notes about the singleton behavior of this class.
# 1. the constructor does not return a singleton reference!
# 2. there is a seperate function called singelton() which will return a
#    singleton reference
# this change was introduces with ResourcePool 0.9909 to allow more flexible
# factories (e.g. factories which do not require all parameters to their 
# constructor) an example of such an factory is the Net::LDAP factory.


sub new($$) {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $key = shift;
	my $self = {};
	$self->{key} = $key; # this is required to make different plain Factories to be different ;)
	$self->{VALID} = 1;

	bless($self, $class);

	return $self;
}

sub create_resource($) {
	my ($self) = @_;
	++$self->{Used};
	if ($self->{VALID}) {
		return ResourcePool::Resource->new($self->{key});
	} else {
		return undef;
	}
}

sub info($) {
	my ($self) = @_;
	return $self->{key};	
}

sub singleton($) {
	my ($self) = @_;
	my $key = $self->mk_singleton_key();
	my $singleton = $self->SUPER::new($key); # parent is Singleton
	if (!$singleton->{initialized}) {
		%{$singleton} = %{$self};
		$singleton->{initialized} = 1;
	}
	return $singleton;
}

sub mk_singleton_key($) {
	my $d = Data::Dumper->new([$_[0]]);
	$d->Indent(0);
	$d->Terse(1);

	# Required to get stable results in presence of sort key randomization
	# See https://rt.cpan.org/Public/Bug/Display.html?id=84265
	$d->Sortkeys(1);

	return $d->Dump();
}


sub _my_very_private_and_secret_test_hook($) {
	my ($not_self) = @_;
	my $self = $not_self->singleton();	
	return $self->{Used};
}

sub _my_very_private_and_secret_test_hook2($$) {
	my ($not_self, $mode) = @_;
	my $self = $not_self->singleton();	
	$self->{VALID} = $mode;
}

1;
