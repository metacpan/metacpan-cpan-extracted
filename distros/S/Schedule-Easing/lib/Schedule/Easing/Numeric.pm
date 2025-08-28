package Schedule::Easing::Numeric;

use strict;
use warnings;
use parent qw/Schedule::Easing::Ease/;
use Carp qw/carp confess/;
use Scalar::Util qw/looks_like_number/;

our $VERSION='0.1.2';

sub _default_keys {
	my ($self)=@_;
	return (
		$self->SUPER::_default_keys(),
		qw/ymin ymax/,
	);
}
sub _default {
	my ($self)=@_;
	return (
		$self->SUPER::_default(),
		match=>qr/(?<value>\d+)/,
		ymin=>0,
		ymax=>1,
	);
}

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		type =>'numeric',
		$class->_default(),
		(ref($ref)?%$ref:()),
		map {$_=>$opt{$_}} grep {defined($opt{$_})} $class->_default_keys()
	);
	return bless(\%self,$class)->validate()->init();
}

sub validate {
	my ($self)=@_;
	$self->SUPER::validate();
	foreach my $k (qw/ymin ymax/) {
		if(!defined($$self{$k}))           { confess("Must be defined:  $k") }
		if(!looks_like_number($$self{$k})) { confess("Must be numeric:  $k") }
	}
	if($$self{ymin}>$$self{ymax}) {
		(@$self{qw/ymin ymax/})=@$self{qw/ymax ymin/};
		carp('ymin>ymax');
		$$self{_err}=1;
	}
	elsif($$self{ymin}==$$self{ymax}) {
		$$self{ymax}=1+$$self{ymin};
		carp('ymin==ymax');
		$$self{_err}=1;
	}
	if($$self{match}!~/\(\?<value>.*?\)/) { confess("Match pattern does not contain 'value':  $$self{match}") }
	return $self;
}

sub init {
	my ($self)=@_;
	$self->SUPER::init();
	$$self{yrange}=$$self{ymax}-$$self{ymin};
	return $self;
}

sub includes {
	my ($self,$ts,%D)=@_;
	if(!defined($ts))       { return 1 }
	if(!defined($D{value})) { return 1 } # possibly a configuration for the default, but should never be called
	if(!looks_like_number($D{value})) { return 1 } # possibly a config, but can't cast non-numerics at this time
	my $p=$$self{_shaper}->($ts,@$self{qw/tsA tsB begin final/},@{$$self{shapeopt}});
	if($p<=0) { return 0 }
	if($p>=1) { return 1 }
	if($D{value}-$$self{ymin}<=$p*$$self{yrange}) { return 1 }
	return 0;
}

sub schedule {
	my ($self,%D)=@_;
	if(!defined($D{value})) { return 0 }
	if(!looks_like_number($D{value})) { return 0 }
	my $p=($D{value}-$$self{ymin})/$$self{yrange};
	if($p<$$self{begin}) { return 0 }
	if($p>$$self{final}) { return }
	return $$self{_unshaper}->($p,@$self{qw/tsA tsB begin final/},@{$$self{shapeopt}});
}

1;
