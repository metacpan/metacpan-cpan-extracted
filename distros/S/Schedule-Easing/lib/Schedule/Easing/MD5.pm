package Schedule::Easing::MD5;

use strict;
use warnings;
use parent qw/Schedule::Easing::Ease/;
use Digest::MD5 qw/md5/;

our $VERSION='0.1.4';

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
	);
}

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		type =>'md5',
		$class->_default(),
		(ref($ref)?%$ref:()),
		map {$_=>$opt{$_}} grep {defined($opt{$_})} $class->_default_keys()
	);
	return bless(\%self,$class)->validate()->init();
}

# validate = SUPER::validate
# init     = SUPER::init

sub includes {
	my ($self,$ts,%D)=@_;
	my $p=$$self{_shaper}->($ts,@$self{qw/tsA tsB begin final/},@{$$self{shapeopt}});
	if($p<=0) { return 0 }
	if($p>=1) { return 1 }
	my $digest='';
	foreach my $k (sort grep {/^digest/} keys %D) { $digest.=$D{$k} }
	if(!$digest) { $digest=$D{message} }
	if(!$digest) { return 1 }
	my $y=unpack('L',substr(md5($digest//''),0,4));
	if(($y%$$self{tsrange})<$p*$$self{tsrange}) { return 1 }
	return 0;
}

sub schedule {
	my ($self,%D)=@_;
	my $digest='';
	foreach my $k (sort grep {/^digest/} keys %D) { $digest.=$D{$k} }
	if(!$digest) { $digest=$D{message} }
	if(!$digest) { return $$self{tsA} }
	my $y=(unpack('L',substr(md5($digest//''),0,4))%$$self{tsrange})/$$self{tsrange};
	if($$self{begin}<$$self{final}) {
		if($y<$$self{begin}) { return 0 }
		if($y>$$self{final}) { return }
	}
	elsif($$self{begin}>$$self{final}) {
		if($y>$$self{begin}) { return 0 }
		if($y<$$self{final}) { return }
	}
	return $$self{_unshaper}->($y,@$self{qw/tsA tsB begin final/},@{$$self{shapeopt}});
}

1;
