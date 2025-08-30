package Schedule::Easing::Ease;

use strict;
use warnings;
use Carp qw/carp confess/;
use Scalar::Util qw/looks_like_number/;

use Schedule::Easing::Function;

our $VERSION='0.1.3';

sub _default_keys { return qw/name match begin final tsA tsB shape shapeopt _warnExpired/ }
sub _default {
	return (
		name =>undef,
		match=>qr/./,
		begin=>0,
		final=>1,
		tsA  =>0,
		tsB  =>1,
		shape=>'linear',
		shapeopt=>[],
		_warnExpired=>0,
	);
}

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=(
		$class->_default(),
		(ref($ref)?%$ref:()),
		map {$_=>$opt{$_}} grep {defined($opt{$_})} $class->_default_keys()
	);
	return bless(\%self,$class)->validate()->init();
}

sub validate {
	my ($self)=@_;
	foreach my $k (qw/tsA tsB begin final/) {
		if(!defined($$self{$k}))           { confess("Must be defined:  $k") }
		if(!looks_like_number($$self{$k})) { confess("Must be numeric:  $k") }
	}
	if(ref($$self{match}) ne 'Regexp') { confess('Must be Regexp:  match') }
	if(ref($$self{name}))              { confess('Must be string:  name') }
	foreach my $k (qw/begin final/) {
		if($$self{$k}<0) { $$self{$k}=0; carp("$k<0"); $$self{_err}=1 }
		if($$self{$k}>1) { $$self{$k}=1; carp("$k>1"); $$self{_err}=1 }
	}
	if($$self{tsA}>=$$self{tsB}) { $$self{tsB}=1+$$self{tsA}; carp('tsA>=tsB'); $$self{_err}=1 }
	if($$self{_warnExpired}&&($$self{tsB}<time())&&(abs(0.5-$$self{final})>=0.5)) {
		if($$self{name}) { carp("Event has expired:  $$self{name}"); $$self{_err}=1 }
		else { carp("Event with tsB=$$self{tsB} has expired"); $$self{_err}=1 }
	}
	$$self{_shaper}  =Schedule::Easing::Function::shape($$self{shape});
	$$self{_unshaper}=Schedule::Easing::Function::inverse($$self{shape});
	return $self;
}

sub init {
	my ($self)=@_;
	$$self{tsrange}=int($$self{tsB}-$$self{tsA});
	return $self;
}

sub includes { die 'Abstract' }
sub schedule { die 'Abstract' }

sub matches {
	my ($self,$message)=@_;
	if($message=~$$self{match}) { return (matched=>1,%+) }
	return;
}

1;
