package Schedule::Easing::Block;

use strict;
use warnings;
use parent qw/Schedule::Easing::Ease/;

our $VERSION='0.1.5';

sub _default_keys {
	my ($self)=@_;
	return (
		$self->SUPER::_default_keys(),
	);
}
sub _default {
	my ($self)=@_;
	return (
		$self->SUPER::_default(),
		match=>qr/.*/,
	);
}

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		type =>'block',
		$class->_default(),
		(ref($ref)?%$ref:()),
		map {$_=>$opt{$_}} grep {defined($opt{$_})} $class->_default_keys()
	);
	return bless(\%self,$class)->validate()->init();
}

sub includes {
	my ($self)=@_;
	return 0;
}

sub schedule {
	my ($self)=@_;
	return;
}

1;
