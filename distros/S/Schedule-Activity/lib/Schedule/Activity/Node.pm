package Schedule::Activity::Node;

use strict;
use warnings;
use List::Util qw/any/;
use Ref::Util qw/is_arrayref is_hashref is_ref/;
use Scalar::Util qw/blessed looks_like_number/;

our $VERSION='0.3.0';

my %property=map {$_=>undef} qw/tmmin tmavg tmmax next finish message attribute note attributes require/;

my %defaults=(
	'tmmax/tmavg'=>5/4,
	'tmavg/tmmin'=>4/3,
	'tmmax/tmmin'=>5/3,
);

sub new {
	my ($ref,%opt)=@_;
	my $class=is_ref($ref)||$ref;
	return bless(\%opt,$class);
}

sub defaulting {
	my ($node)=@_;
	my $mult=sub { my ($x,$y)=@_; if(defined($y)) { return $x*$y } return };
	my @lln;
	foreach my $k (qw/tmmin tmavg tmmax/) {
		if(looks_like_number($$node{$k})) { push @lln,1 }
		else { delete($$node{$k}); push @lln,0 }
	}
	if(any {!$_} @lln) {
		if($lln[1]) {
			$$node{tmmax}//=$$node{tmavg}*$defaults{'tmmax/tmavg'};
			$$node{tmmin}//=$$node{tmavg}/$defaults{'tmavg/tmmin'};
		}
		elsif($lln[0]) {
			if($lln[2]) { $$node{tmavg}=0.5*($$node{tmmin}+$$node{tmmax}) }
			else {
				$$node{tmmax}//=$$node{tmmin}*$defaults{'tmmax/tmmin'};
				$$node{tmavg}//=$$node{tmmin}*$defaults{'tmavg/tmmin'};
			}
		}
		elsif($lln[2]) {
			$$node{tmavg}//=$$node{tmmax}/$defaults{'tmmax/tmavg'};
			$$node{tmmin}//=$$node{tmmax}/$defaults{'tmmax/tmmin'};
		}
	}
	return;
}

sub nextnames {
	my ($self,$filtered,$node)=@_;
	if(!defined($node)) { $node=$$self{next}; $filtered=1 }
	if(is_arrayref($node)) {
		my @res;
		foreach my $next (@$node) {
			if(!$filtered)                            { push @res,$next }
			elsif(defined($next)&&!is_ref($next))     { push @res,$next }
			elsif(is_hashref($next)&&$$next{keyname}) { push @res,$$next{keyname} }
		}
		return @res;
	}
	elsif(is_hashref($node)) { return keys %$node }
	elsif(!defined($node))   { return }
	die 'Expected array/hash'; # only used during validation, not runtime
}

sub nextremap {
	my ($self,$mapping)=@_;
	if(is_arrayref($$self{next})) {
		my @nexts=grep {defined($_)} map {$$mapping{$_}} @{$$self{next}};
		if(@nexts) { $$self{next}=\@nexts }
		else       { delete($$self{next}) }
	}
	elsif(is_hashref($$self{next})) {
		while(my ($name,$next)=each %{$$self{next}}) {
			my $x=$$mapping{$name};
			if($x) { $$next{node}=$x }
			else   { delete($$self{next}{$name}) }
		}
		if(!%{$$self{next}}) { delete($$self{next}) }
	}
	return $self;
}

sub validate {
	my (%node)=@_;
	if($node{_valid}) { return }
	my (@errors,@invalids,@tmseq);
	foreach my $k (grep {!exists($property{$_})} keys(%node)) { push @errors,"Invalid key:  $k" }
	foreach my $k (map {"tm$_"} qw/min avg max/) {
		if(defined($node{$k})) {
			if   (!looks_like_number($node{$k})) { push @errors,"Invalid value:  $k" }
			elsif($node{$k}<0)                   { push @errors,"Negative value:  $k" }
			else                                 { push @tmseq,$node{$k} }
		}
		else { push @invalids,$k }
	}
	@invalids=sort(@invalids);
	if(@invalids&&($#invalids!=2)) { push @errors,'Incomplete time specification missing:  '.join(' ',@invalids) }
	if($#tmseq==2) {
		if($tmseq[0]>$tmseq[1]) { push @errors,'Invalid:  tmmin>tmavg' }
		if($tmseq[1]>$tmseq[2]) { push @errors,'Invalid:  tmavg>tmmax' }
	}
	if(exists($node{next})) {
		my @nexts;
		eval { @nexts=nextnames(undef,0,$node{next}) };
		if($@) { push @errors,'Expected array/hash:  next' }
		@invalids=grep {!defined($_)||is_ref($_)} @nexts;
		if(@invalids) { push @errors,'Invalid entry in:  next' }
		if(is_hashref($node{next})) {
			my $weight=0;
			foreach my $x (map {$$_{weight}//1} values %{$node{next}}) { $weight+=$x }
			if($weight<=0) { push @errors,'Sum of weights must be positive' }
		}
	}
	if(exists($node{finish})) {
		if(!defined($node{finish})||is_ref($node{finish})) { push @errors,'Expected name:  finish' }
	}
	if(!@errors) { $node{_valid}=1 }
	return @errors;
}

sub slack  { my ($self)=@_; return ($$self{tmavg}//0)-($$self{tmmin}//$$self{tmavg}//0) }
sub buffer { my ($self)=@_; return ($$self{tmmax}//$$self{tmavg}//0)-($$self{tmavg}//0) }

sub increment {
	my ($self,$tm,$slack,$buffer)=@_;
	if(is_ref($tm))     { $$tm    +=$$self{tmavg}//0 }
	if(is_ref($slack))  { $$slack +=$self->slack()   }
	if(is_ref($buffer)) { $$buffer+=$self->buffer()  }
	return $self;
}

sub _randweighted {
	my ($weight,$L)=@_;
	my $y=rand($weight);
	my $i=0;
	while(($i<$#$L)&&($y>($$L[$i][1]{weight}//1))) { $y-=$$L[$i][1]{weight}//1; $i++ }
	return $$L[$i][1]{node}//$$L[$i][0];
}

sub nextrandom {
	my ($self,%opt)=@_;
	if(!$$self{next}) { return }
	my (@candidates,$weight);
	if(is_arrayref($$self{next})) {
	foreach my $next (@{$$self{next}}) {
		if($opt{not}&&($opt{not} eq $next)) { next }
		if(!is_ref($next)) { push @candidates,$next; next }
		if(!is_hashref($next)) { next }
		if(blessed($$next{require})&&$opt{attr}) {
			if(!$$next{require}->matches($opt{tm},%{$opt{attr}})) { next } }
		push @candidates,$next;
	} }
	elsif(is_hashref($$self{next})) {
	while(my ($next,$href)=each %{$$self{next}}) {
		if(!is_hashref($href)) { next }
		if($$href{node}) {
			if($opt{not}&&($opt{not} eq $$href{node})) { next }
			if(blessed($$href{node}{require})&&$opt{attr}) {
				if(!$$href{node}{require}->matches($opt{tm},%{$opt{attr}})) { next } } }
		my $w=$$href{weight}//1;
		if($w>0) { $weight+=$w; push @candidates,[$next,$href] }
	} }
	if(!@candidates) { return }
	if($weight) { return _randweighted($weight,\@candidates) }
	else { return $candidates[ int(rand(1+$#candidates)) ] }
}

sub hasnext {
	my ($self,$node)=@_;
	if(!$$self{next}) { return }
	if(is_arrayref($$self{next})) { return (any {$_ eq $node} @{$$self{next}}) }
	if(is_hashref($$self{next}))  { return (any {$$_{node} eq $node} values %{$$self{next}}) }
	return;
}

1;
